import Foundation
import ArgumentParser

@main
struct LabelParser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "docent",
    subcommands: [Summarize.self, ParseLabel.self, GrpcServer.self, GrpcSummarize.self, GrpcParseLabel.self ],
  )
}
