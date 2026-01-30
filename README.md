# Docent

Swift package for "museum-related" tasks using on-device machine learning (large language) models.

* Deriving structured data for museum wall label text.
* Summarizing texts in to new texts with a maximum characted length.

_This package used to be called `WallLabel` but was renamed to be less specific._

## Background

[WallLabel – Experiments with Apple's open source machine-learning frameworks](https://millsfield.sfomuseum.org/blog/2025/10/29/label/)

## Motivation

This is a Swift package for "museum-related" tasks using on-device machine learning (large language) models. The definition of "museum-related" is vague and debateable but SFO Museum is a museum and these tools target things we do so there you go.

Currently it supports using the built-in "Foundation" models that ship with AppleOS 26 devices and models available from HuggingFace which are manipulated using the Apple MLX packages (and which run on pre AppleOS 26 devices). Support for manipulating models using the [llama.cpp XCFramework Swift bindings](https://github.com/ggml-org/llama.cpp?tab=readme-ov-file#xcframework) are in the works but incomplete as of this writing.

## Documentation

Documentation is "okay" but incomplete at this time.

## Usage

### Parsing wall labels

```
import Logging
import WallLabel

let parser_uri = "mlx://?model=mlx-community/Olmo-3-7B-Instruct-8bit"
let label_text = "YOUR LABEL TEXT HERE"

let logger = Logger(label: "org.sfomuseum.docent.label")

var label_parser: Parser
        
do {
	label_parser = try await NewParser(parser_uri: parser_uri, logger: logger)
} catch {
	// throw error here...
}
        
let parse_rsp = await label_parser.parse(text: label_text)
        
switch parse_rsp {
case .success(let label):
	// do something with label here
case .failure(let error):
	// throw error here
}	
```

_Note: The `Parser` class will probably be renamed (to something like `WallLabelParser`) in future releases._

### Summarzing texts

```
import Logging
import Summarizer

let summarizer_uri = "mlx://?model=mlx-community/Olmo-3-7B-Instruct-8bit"
let text = "YOUR TEXT TO SUMMARIZE"
let max_length = 77

let logger = Logger(label: "org.sfomuseum.docent.summarize")

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
```
        
## URIs

### FoundationModels

To use the built-in "Foundation" models that ship with AppleOS 26 devices you would use the following syntax:

```
foundation://
```

### MLX

To use models available from HuggingFace and manipulated using the Apple [MLX Swift libraries](https://github.com/ml-explore/mlx-swift/) you would use the following syntax:

```
mlx://?model={MODEL_NAME}
```

_See the [ml-explore/mlx-swift-lm](https://github.com/ml-explore/mlx-swift-lm) package, which is what does all the "heavy lifting", for details._

## Tools

### docent

```
$> docent -h
USAGE: docent <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  summarize               Command line tool for summarizing text.
  label                   Parse the text of a wall label in to JSON-encoded structured data.

  See 'docent help <subcommand>' for detailed help.
```  
 
#### docent label

Parse the text of a wall label in to JSON-encoded structured data.

```
$> docent label -h
OVERVIEW: Parse the text of a wall label in to JSON-encoded structured data.

USAGE: docent label [--parser_uri <parser_uri>] [--label_text <label_text>] [--instructions <instructions>] [--verbose <verbose>]

OPTIONS:
  --parser_uri <parser_uri>
                          The parser scheme is to use for parsing wall label text. (default: mlx://?model=mlx-community/Olmo-3-7B-Instruct-8bit)
  --label_text <label_text>
                          The label text to parse in to structured data.
  --instructions <instructions>
                          Optional custom instructions to use when parsing wall label text.
  --verbose <verbose>     Enable verbose logging (default: false)
  -h, --help              Show help information.
```
  
For example:

```
$> docent label --verbose=true --label_text "Honeywell CT87K Round Heat-Only Manual Current production model introduced in 1953 Designed by Henry Dreyfuss Associates (USA, founded Manufactured by Honeywell, Inc. (Minneapolis, Minnesota, USA) Plastic, mechanical and electrical components, lithium battery, mercury-free thermostat dials, domestic, consumer, interface, interaction, personal environmental control Purchased from manufacturer. Henry Dreyfuss began designing the Honeywell Round Thermostat in 1943. He observed that rectangular thermostats often sit crooked on the wall; a round device would properly. The Honeywell be easier to install Round, released a allows users decade later, to adjust temperature with a simple twist of the dial. Dreyfuss's design also promoted customization: users could remove the protective cover and paint the device to match the room. Today, the Honeywell Round remains one of the world's most ubiquitous thermostats." | jq

2026-01-29T13:16:52-0800 debug org.sfomuseum.docent.label: [WallLabel] Loading mlx-community/Olmo-3-7B-Instruct-8bit 100.0% complete
2026-01-29T13:17:07-0800 debug org.sfomuseum.docent.label: [WallLabel] Time to parse wall label 13.41082501411438 seconds

{
  "latitude": 0,
  "medium": "Plastic, mechanical and electrical components, lithium battery, mercury-free thermostat dials",
  "longitude": 0,
  "creator": "Honeywell, Inc.",
  "title": "Honeywell CT87K Round Heat-Only Manual Thermostat",
  "location": "",
  "accession_number": "",
  "timestamp": 1769721427,
  "input": "Honeywell CT87K Round Heat-Only Manual Current production model introduced in 1953 Designed by Henry Dreyfuss Associates (USA, founded Manufactured by Honeywell, Inc. (Minneapolis, Minnesota, USA) Plastic, mechanical and electrical components, lithium battery, mercury-free thermostat dials, domestic, consumer, interface, interaction, personal environmental control Purchased from manufacturer. Henry Dreyfuss began designing the Honeywell Round Thermostat in 1943. He observed that rectangular thermostats often sit crooked on the wall; a round device would properly. The Honeywell be easier to install Round, released a allows users decade later, to adjust temperature with a simple twist of the dial. Dreyfuss's design also promoted customization: users could remove the protective cover and paint the device to match the room. Today, the Honeywell Round remains one of the world's most ubiquitous thermostats.",
  "date": "1953",
  "creditline": "Purchased from manufacturer; designed by Henry Dreyfuss Associates (USA); manufactured by Honeywell, Inc. (Minneapolis, Minnesota, USA)"
}
```

Or:

```
$> docent label --verbose=true --label_text "Promotion, Chiat/ Day: Effective Brick Design Director: Tibor Kalman (American, b. Hungary, 1949–1999); Firm: M&Co (United States); USA offset lithography Gift of Tibor Kalman/ M & Co. Cooper Hewitt Smithsonian National Design Museum 1993-151-257-1" | jq

2026-01-29T13:23:30-0800 debug org.sfomuseum.docent.label: [WallLabel] Loading mlx-community/Olmo-3-7B-Instruct-8bit 100.0% complete
2026-01-29T13:23:42-0800 debug org.sfomuseum.docent.label: [WallLabel] Time to parse wall label 10.06504201889038 seconds

{
  "medium": "offset lithography",
  "timestamp": 1769721822,
  "longitude": 0,
  "accession_number": "1993-151-257-1",
  "creator": "Tibor Kalman",
  "title": "Promotion",
  "creditline": "Gift of Tibor Kalman/ M & Co. Cooper Hewitt Smithsonian National Design Museum 1993-151-257-1",
  "date": "",
  "location": "Cooper Hewitt Smithsonian National Design Museum",
  "latitude": 0,
  "input": "Promotion, Chiat/ Day: Effective Brick Design Director: Tibor Kalman (American, b. Hungary, 1949–1999); Firm: M&Co (United States); USA offset lithography Gift of Tibor Kalman/ M & Co. Cooper Hewitt Smithsonian National Design Museum 1993-151-257-1"
}
```
#### docent summarize

Command line tool for summarizing text.

```
$> /docent summarize -h
OVERVIEW: Command line tool for summarizing text.

USAGE: docent summarize [--summarizer_uri <summarizer_uri>] [--text <text>] [--max_length <max_length>] [--verbose <verbose>]

OPTIONS:
  --summarizer_uri <summarizer_uri>
                          A URI denoting the framework and model to use for summarizing text. (default: mlx://?model=mlx-community/Olmo-3-7B-Instruct-8bit)
  --text <text>           The text to summarize
  --max_length <max_length>
                          The maximum length of the summary. (default: 77)
  --verbose <verbose>     Enable verbose logging (default: false)
  -h, --help              Show help information.
```
  
For example:

```
$> docent summarize --verbose=true --summarizer_uri 'mlx://?model=mlx-community/Olmo-3-7B-Instruct-8bit' --text 'Timetable issued by Sunworld International Airways, effective April 1, 1986; four page double-sided fold-out; yellow cover with route map and text announcing new service to Los Angeles and Milwaukee.'
2026-01-29T13:19:34-0800 debug org.sfomuseum.docent.summarize: [Summarizer] Loading mlx-community/Olmo-3-7B-Instruct-8bit 100.0% complete
2026-01-29T13:20:04-0800 debug org.sfomuseum.docent.summarize: [Summarizer] Time to summarize text 1.6216939687728882 seconds
Sunworld announced new LA and Milwaukee routes in a 1986 four-page fold-out timetable.
```

#### Building

The easiest thing to build the `docent` tool is use the handy `macos` Makefile targets.


```
$> make macos

xcodebuild -destination 'platform=macOS' -scheme docent -configuration Release
Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -destination platform=macOS -scheme docent -configuration Release

...lots and lots of build gibberish and other output
```

This will build the `wall-label` tool in a folder called `{YOUR_HOMEDIR}/Library/Developer/Xcode/DerivedData/Docent-{SOME_RANDOM_STRING}/Build/Products/Release/`. This is probably the correct thing to do from an overall security perspective but it's still kind of annoying since that path is not explicitly called out at the end and you have to fish around for it in the build gibberish. Oh well...

A couple things to note:

1. The use `xcodebuild` to compile tools. That's because the MLX libraries depend on compiling a `default.metallib` file which a plain-vanilla `swift build` command doesn't know how to do.
2. The use of the `Release` target which is what appears to be necessary to bundle said `default.metallib` with the final binary. At least I think that's why. The documentation around bundling Metal shaders with command line tools is a bit confusing to me still.

## See also:

* https://github.com/ml-explore/mlx-swift
* https://github.com/ml-explore/mlx-swift-lm
* https://developer.apple.com/documentation/foundationmodels
