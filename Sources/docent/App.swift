import Foundation
import ArgumentParser

@main
struct LabelParser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "docent",
    subcommands: [Summarize.self, Label.self, Serve.self],
    // defaultSubcommand: Summarize.self,
  )
}
