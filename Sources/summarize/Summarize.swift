import Foundation
import ArgumentParser

@main
struct LabelParser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "summarize",
    subcommands: [Summarize.self],
    defaultSubcommand: Summarizer.self,
  )
}
