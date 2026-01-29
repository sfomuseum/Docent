import Foundation
import ArgumentParser

@main
struct LabelParser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "docent",
    subcommands: [Summarize.self, Label.self],
    // defaultSubcommand: Summarize.self,
  )
}
