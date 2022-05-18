import AsyncShell
import Foundation

public struct Job {
    public var archivePath: String
    public var rootPath: String
    public var outputPath: String
    public var files: Set<String> = []

    public init(
        archivePath: String,
        rootPath: String,
        outputPath: String,
        files: Set<String> = []
    ) {
        self.archivePath = archivePath
        self.rootPath = rootPath
        self.outputPath = outputPath
        self.files = files
    }
}

extension Job {
    private func absolutePath(for relativePath: String) -> String {
        URL(fileURLWithPath: "\(rootPath)/\(relativePath)").standardizedFileURL.path
    }

    private var knownFiles: Set<String> {
        get async throws {
            try await ShellCommand("xcrun xccov view --file-list \(archivePath)")
                .launchToProcessOutput(
                    standardError: FileHandle.nullDevice
                ) { bytes in
                    var trackedFiles: Set<String> = []
                    for try await line in bytes.lines {
                        trackedFiles.insert(line.trimmingCharacters(in: .whitespaces))
                    }
                    return trackedFiles
                }
        }
    }

    private var filesToProcess: Set<String> {
        get async throws {
            let knownFiles = try await self.knownFiles
            var toProcess: Set<String> = []
            if files.isEmpty {
                let prefix = URL(fileURLWithPath: rootPath).standardizedFileURL.path + "/"
                for absolutePath in knownFiles {
                    guard absolutePath.starts(with: prefix) else { continue }
                    let relativePath = String(absolutePath.dropFirst(prefix.count))
                    toProcess.insert(relativePath)
                }
            } else {
                for relativePath in files {
                    guard knownFiles.contains(absolutePath(for: relativePath)) else { continue }
                    toProcess.insert(relativePath)
                }
            }
            return toProcess
        }
    }

    private func processCoverage(for relativePath: String) async throws -> [CodecovLine] {
        return try await ShellCommand("xcrun xccov view --file \(absolutePath(for: relativePath)) \(archivePath)")
            .launchToProcessOutput(
                standardError: FileHandle.nullDevice
            ) { bytes in
                var processor = XccovProcessor(relativePath: relativePath)
                for try await line in bytes.lines {
                    processor.process(line: line)
                }
                return processor.finalize()
            }
    }

    public func run() async throws {
        let list = try await filesToProcess
        print("To process \(list.count) files.")


        let sum = await list
            .parallelCompactMapToDictionary { relativePath -> (String, [CodecovLine])? in
                do {
                    let list = try await self.processCoverage(for: relativePath)
                    return (relativePath, list)
                } catch {
                    var log = ""
                    print(
                        "Failed to process file: \(relativePath)",
                        error.localizedDescription,
                        separator: "\n",
                        terminator: "\n",
                        to: &log
                    )
                    FileHandle.standardError.write(log.data(using: .utf8)!)
                    return nil
                }
            }

        print("To write to \(outputPath)")

        let wrapper = ["coverage": sum]
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(wrapper)
        try data.write(to: URL(fileURLWithPath: outputPath))

        print("Done!")
    }
}
