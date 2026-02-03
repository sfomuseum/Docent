import ArgumentParser

struct Version: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Print version number")
    
    func run() async throws {
        print(version)
    }
}
