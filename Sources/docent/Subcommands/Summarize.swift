import ArgumentParser

import Logging
import Summarizer

struct Summarize: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Command line tool for summarizing text.")
    
    @Option(help: "A URI denoting the framework and model to use for summarizing text.")
    var summarizer_uri: String = default_summarizer_uri
    
    @Option(help: "The maximum length of the summary.")
    var max_length: Int = 77

    @Option(help: "The maximum number of attempts to make summarizing the text to be no longer than the value of the --max_length flag.")
    var max_attempts: Int = 1
    
    @Option(help: "Enable verbose logging")
    var verbose: Bool = false
    
    @Argument(help: "The text to summarize for. If \"-\" then data is read from STDIN. If the first argument is a valid path to a local file then the text of that file will be used. Otherwise all remaining arguments will be concatenated (with a space) and used as the text to summarize.")
    var args: [String]
    
    func run() async throws {
        
        var logger = Logger(label: "org.sfomuseum.docent.summarize")

        if verbose {
            logger.logLevel = .debug
        }
        
        var text: String
        
        do {
             text = try TextFromArgs(args: args)
        } catch {
            logger.error("Failed to derive text from args \(error)")
            throw error
        }
        
        var summarizer: Summarizer
        
        do {
            summarizer = try await NewSummarizer(summarizer_uri, logger: logger)
        } catch {
            throw error
        }
        
        let req = SummarizeWithRetriesRequest(
            text: text,
            max_length: max_length,
            max_attempts: max_attempts,
        )
        
        let rsp = await SummarizeWithRetries(summarizer, req, logger: logger)
                
        switch rsp {
        case .success(let rsp):
            print(rsp.summary)
        case .failure(let err):
            throw err
        }
        
    }
}
