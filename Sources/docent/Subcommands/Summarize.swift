import ArgumentParser

import Logging
import Summarizer

struct Summarize: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Command line tool for summarizing text.")
    
    @Option(help: "A URI denoting the framework and model to use for summarizing text.")
    var summarizer_uri: String = "mlx://?model=mlx-community/Olmo-3-7B-Instruct-8bit"
    
    @Option(help: "The text to summarize")
    var text: String = ""
    
    @Option(help: "The maximum length of the summary.")
    var max_length: Int = 77
    
    @Option(help: "Enable verbose logging")
    var verbose: Bool = false
    
    func run() async throws {
        
        var logger = Logger(label: "org.sfomuseum.docent.summarize")

        if verbose {
            logger.logLevel = .debug
        }
        
        var summarizer: Summarizer
        
        do {
            summarizer = try await NewSummarizer(summarizer_uri, logger: logger)
        } catch {
            throw error
        }
        
        let rsp = await summarizer.summarize(text: text, maxLength: max_length)
        
        switch rsp {
        case .success(let summary):
            print(summary)
        case .failure(let err):
            throw err
        }
        
    }
}
