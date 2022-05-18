import ArgumentParser
import Library

@main
struct Entry: AsyncParsableCommand {
    @Option(help: "Path of the .xccovarchive directory.")
    var archivePath: String
    @Option(help: "Path of the root directory for your source files.")
    var rootPath: String
    @Option(help: "Path of the JSON output.")
    var outputPath: String
    @Argument(parsing: .remaining, help: "A list of source files for which code coverage will be processed. If empty, all files in the archive will be processed.")
    var files: [String] = []

    func run() async throws {
        var job = Job(archivePath: archivePath, rootPath: rootPath, outputPath: outputPath)
        job.files = Set(files)
        try await job.run()
    }
}
