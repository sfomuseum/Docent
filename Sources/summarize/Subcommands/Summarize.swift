import ArgumentParser

import Logging
import WallLabel

enum ParseErrors: Error {
    case invalidParser
    case stringifyError
}

struct Summarize: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "")
    
    @Option(help: "The parser scheme is to use for parsing wall label text.")
    var summarizer_uri: String = "mlx://?model=llama3.2:1b"
    
    @Option(help: "The text to summarize")
    var text: String = ""
    
    @Option(help: "The maximum length of the summary.")
    var max_length: Int = 77
    
    @Option(help: "Enable verbose logging")
    var verbose: Bool = false
    
    func run() async throws {
        
        var logger = Logger(label: "org.sfomuseum.summarize")

        if verbose {
            logger.logLevel = .debug
        }
        
        var summarizer: Summarizer
        
        do {
                summarizer = try NewSummarizer(summarizer_uri, logger: logger)
        } catch {
            throw error
        }
        
        let rsp = await label_parser.summarize(text: text, maxLength: max_length)
        
        switch rsp {
        case .success(let summary):
            print(summary)
        case .failure(let err):
            throw err
        }
        
    }
}
