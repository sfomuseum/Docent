# Docent

Swift package for "museum-related" tasks using on-device machine learning (large language) models.

* Deriving structured data for museum wall label text.
* Summarizing texts in to new texts with a maximum characted length.

_This package used to be called `WallLabel` but was renamed to be less specific._

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

To use the built-in "Foundation" models that ship with AppleOS 26 devices create a new `Parser` instance using the following syntax:

```
foundation://
```

### MLX

To use models available from HuggingFace and manipulated using the Apple [MLX Swift libraries](https://github.com/ml-explore/mlx-swift/) create a new `Parser` instance using the following syntax:

```
mlx://?model={MODEL_NAME}
```

_See the [ml-explore/mlx-swift-lm](https://github.com/ml-explore/mlx-swift-lm) package, which is what does all the "heavy lifting", for details._

### Disabled

The disable a tool or service use the following syntax:

```
disabled://
```

## Tools

### docent

```
$> docent <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  summarize               Command line tool for summarizing text.
  label                   Parse the text of a wall label in to JSON-encoded structured data.
  grpc-server             gRPC server for exposing "docent"-related tasks.
  grpc-client             gRPC client for interacting with a "docent" server.

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
2026-01-29T13:17:07-0800 debug org.sfomuseum.docent.label: [WallLabel] {"title": "Honeywell CT87K Round Heat-Only Manual Thermostat", "date": "1953", "creator": "Honeywell, Inc.", "creditline": "Purchased from manufacturer; designed by Henry Dreyfuss Associates (USA); manufactured by Honeywell, Inc. (Minneapolis, Minnesota, USA)", "location": "", "medium": "Plastic, mechanical and electrical components, lithium battery, mercury-free thermostat dials", "accession_number": "", "input": "Honeywell CT87K Round Heat-Only Manual current model introduced in 1953 Designed by Henry Dreyfuss Associates (USA, founded) Manufactured by Honeywell, Inc. (Minneapolis, Minnesota, USA) Plastic, mechanical and electrical components, lithium battery, mercury-free thermostat dials, domestic, consumer, interface, interaction, personal environmental control Purchased from manufacturer. Henry Dreyfuss began designing the Honeywell Round Thermostat in 1943. It was designed to sit straight on the wall and allow easy temperature adjustment with a twist of the dial. The design also allowed for customization by removing the cover to paint the device."}
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

#### docent grpc-server

gRPC server for exposing "docent"-related tasks.

```
$> docent grpc-server -h
OVERVIEW: gRPC server for exposing "docent"-related tasks.

USAGE: docent grpc-server [--host <host>] [--port <port>] [--label_parser_uri <label_parser_uri>] [--summarizer_uri <summarizer_uri>] [--summarizer_max_length <summarizer_max_length>] [--max_receive_message_length <max_receive_message_length>] [--tls_certificate <tls_certificate>] [--tls_key <tls_key>] [--verbose <verbose>]

OPTIONS:
  --host <host>           The host name to listen for new connections (default: 127.0.0.1)
  --port <port>           The port to listen on (default: 8080)
  --label_parser_uri <label_parser_uri>
                          A URI denoting the framework and model to use for parsing wall labels. (default: mlx://?model=mlx-community/Olmo-3-7B-Instruct-8bit)
  --summarizer_uri <summarizer_uri>
                          A URI denoting the framework and model to use for summarizing text. (default: mlx://?model=mlx-community/Olmo-3-7B-Instruct-8bit)
  --summarizer_max_length <summarizer_max_length>
                          The default value and maximum length for summary texts. (default: 77)
  --max_receive_message_length <max_receive_message_length>
                          Sets the maximum message size in bytes the server may receive. If 0 then the swift-grpc defaults will be used. (default: 0)
  --tls_certificate <tls_certificate>
                          The TLS certificate chain to use for encrypted connections
  --tls_key <tls_key>     The TLS private key to use for encrypted connections
  --verbose <verbose>     Enable verbose logging (default: false)
  -h, --help              Show help information.
 ```
  
For example:

```
$> docent grpc-server --verbose=true

2026-01-30T15:42:36-0800 debug org.sfomuseum.docent.grpcd: [docent] Instantiate tools from shared model mlx-community/Olmo-3-7B-Instruct-8bit

2026-01-30T15:42:43-0800 debug org.sfomuseum.docent.grpcd: [docent] Loading mlx-community/Olmo-3-7B-Instruct-8bit 100.0% complete
2026-01-30T15:42:50-0800 info org.sfomuseum.docent.grpcd: [docent] listening for requests on 127.0.0.1:8080)
2026-01-30T15:43:57-0800 debug org.sfomuseum.docent.grpcd: [Summarizer] Time to summarize text 2.1631200313568115 seconds
2026-01-30T15:43:57-0800 info org.sfomuseum.docent.grpcd: [docent] Time to summary text 2.1631510257720947 seconds
```

#### docent grpc-client

gRPC client for interacting with a "docent" server.

```
$> docent grpc-client -h
OVERVIEW: gRPC client for interacting with a "docent" server.

USAGE: docent grpc-client [--host <host>] [--port <port>] [--verbose <verbose>] [--action <action>] <args> ...

ARGUMENTS:
  <args>                  The text to generate embeddings for. If "-" then data is read from STDIN. If the first argument is a valid path to a local file then the text of that file will
                          be used. Otherwise all remaining arguments will be concatenated (with a space) and used as the text to generate embeddings for.

OPTIONS:
  --host <host>           The host name for the gRPC server. (default: 127.0.0.1)
  --port <port>           The port for the gRPC server. (default: 8080)
  --verbose <verbose>     Enable verbose logging (default: false)
  --action <action>       The gRPC server to invoke. Valid options are: label-parser, summarize.
  -h, --help              Show help information.
```

For example, parsing wall labels:

```
$> /usr/local/bin/docent grpc-client --action=label-parser "Honeywell CT87K Round Heat-Only Manual Current production model introduced in 1953 Designed by Henry Dreyfuss Associates (USA, founded Manufactured by Honeywell, Inc. (Minneapolis, Minnesota, USA) Plastic, mechanical and electrical components, lithium battery, mercury-free thermostat dials, domestic, consumer, interface, interaction, personal environmental control Purchased from manufacturer. Henry Dreyfuss began designing the Honeywell Round Thermostat in 1943. He observed that rectangular thermostats often sit crooked on the wall; a round device would properly. The Honeywell be easier to install Round, released a allows users decade later, to adjust temperature with a simple twist of the dial. Dreyfuss's design also promoted customization: users could remove the protective cover and paint the device to match the room. Today, the Honeywell Round remains one of the world's most ubiquitous thermostats." | jq

{
  "date": "1953",
  "title": "Honeywell CT87K Round Heat-Only Manual Thermostat",
  "timestamp": 1769819576,
  "accession_number": "",
  "latitude": 0,
  "longitude": 0,
  "creditline": "Purchased from manufacturer. Designed by Henry Dreyfuss Associates (USA).",
  "medium": "Plastic, mechanical and electrical components, lithium battery, mercury-free thermostat dials",
  "input": "Honeywell CT87K Round Heat-Only Manual Current production model introduced in 1953 Designed by Henry Dreyfuss Associates (USA, founded Manufactured by Honeywell, Inc. (Minneapolis, Minnesota, USA) Plastic, mechanical and electrical components, lithium battery, mercury-free thermostat dials, domestic, consumer, interface, interaction, personal environmental control Purchased from manufacturer. Henry Dreyfuss began designing the Honeywell Round Thermostat in 1943. He observed that rectangular thermostats often sit crooked on the wall; a round device would properly. The Honeywell be easier to install Round, released a allows users decade later, to adjust temperature with a simple twist of the dial. Dreyfuss's design also promoted customization: users could remove the protective cover and paint the device to match the room. Today, the Honeywell Round remains one of the world's most ubiquitous thermostats.",
  "location": "",
  "creator": "Honeywell, Inc."
}
```

Or summarizing text. For example, here are the summaries of each paragraph in Steve Yegge's [Software Survival 3.0](https://steve-yegge.medium.com/software-survival-3-0-97a2a6255f7b) blog post:

```
foreach line ( "`cat yegge.txt`" )
foreach? docent grpc-client --action=summarize $line                             
foreach? end

Wrote AI-assisted software, had success with Beads and Gas Town; recognized AI progress accelerating.
Extrapolation from 2023 tech trends predicts orchestration by early 2026.
Found Gas Town, a functional AI-powered system, sparking a new tech wave in 2025.
Predicted future trends in tech, from junior dev struggles to new orchestrators and beyond.
Belief in curves drives my predictive power.
Only software AI can create is likely to survive.
Old man feeds illegal squirrel that shows up for his outings.
Marv’s squirrel’s knowledge of evolutionary biology matches mine and scores similarly on expert exams.
The speaker believes their prediction method works based on Karpathy and Amodei's views.
Trying to persuade the recipient.
AI lets companies build custom SaaS faster than buying, accelerating home-grown solutions by 2026.
AI is disrupting SaaS beyond SaaS itself—support, low-code tools, writing assistants, and IDEs face growing pressure.
AI threatens most software sectors; caution is wise.
Rationale for choosing the best among competing options.
Efficient resource use favors successful tools in constrained systems like Software 3.0.
Systems must reduce compute costs to cut energy use and expenses, using smaller models where possible and optimizing model allocation.
Old-fashioned software with the right traits will endure alongside AI.
Token-saving tools likely persist due to efficiency; others may be replaced.
Plan for software survival in the upcoming Software 3.0 transition.
Measures how well a strategy survives over time.
Model predicts survival of tool T using Squirrel Math formula.
Survival chance increases with savings, usage, and helpfulness, but decreases with awareness and friction costs.
Tools survive if value/cost >1; high ratios make them essential and hard to replace.
How often and broadly a tool is used affects its value; niche tools need bigger savings to justify limited use, but useful multi-purpose tools can survive with modest savings.
H measures human creativity impact; favors unique, non-efficient designs.
Awareness cost: energy spent teaching agents about a tool at training or inference.
Friction in tools causes errors and switching to less efficient options if learning is hard. Low friction boosts adoption.
A mental model for thinking about software survival amid resource-limited AI.
Discussed selection model with AI, convinced it works despite initial disagreements.
Tools that save tokens and are cost-effective get selected, others are outcompeted.
Awareness cost rises in competitive markets; tools may need extra effort to be noticed.
Squirrel Model offers 6 survival levers for software, focusing on cost-saving, long-term strategies.
Save knowledge by saving words.
Maximizing savings boosts survival ratio via first two levers, even with superintelligent AIs.
Agents use pattern matching, not efficient algorithms, for calculations.
Using LLMs for math is inefficient on GPU; better to use CPU tools.
Agents use tools to save effort and cognitive load, valuing smart laziness.
Agents can use existing tools or create new ones for delegated tasks.
Use tools to reduce their cognitive load and wait for results.
Squeezes insights into compact form
Software compresses valuable insights for efficient reuse.
Git embodies decades of collaborative change-tracking wisdom.
Recreating Git by AI is too costly and inefficient. Nuts.
Old systems are better crystallized knowledge; complex systems like Kubernetes are durable solutions.
AI uses insight compression to simplify complex ideas into memorable forms.
Optimizes energy use per reaction output in biological systems.
grep is efficient; no need to reinvent it.
Grep uses CPU for simple but effective pattern matching, outperforming complex GPU methods.
Using inference to mimic grep is irrational across most criteria. LLMs prefer calculators over coding when possible. Tools like parsers and ImageMagick enable these efficiencies.
Use smarter algorithms or cheaper workers to save compute costs.
Versatile tool for various tasks.
Temporal exemplifies tools vital for agentic workflows in 2026.
Temporal is hard to replicate due to its unique approach and broad utility in workflow modeling.
Dolt, an 8-year-old OSS, gains traction with agent workflows for prod/devops, but lacks initial awareness solution.
Agents' growth makes code search harder and less like grep, requiring better search engines with scalable, efficient solutions.
Hopeful tech growth: new AI agents, data insights, and better knowledge sharing.
Software used widely by many agents fuels more adoption and growth.
Promote awareness through public campaigns.
Need awareness beyond just tools—solve pre-sales to find users like Beads.
Awareness cost: gain popularity to reduce the energy needed for others to know about your tool.
Spend money on better product documentation and advertising, but a direct solution exists.
Companies pay to improve their AI models by training them on vendor tools via specialized evaluations.
SEO for agents is rising; trust and recognition matter more than just being good.
Prioritize agent-friendly tools if you can’t spend on pre-training or ads.
Make your tool easy for new users to understand.
Reduce resistance to improve efficiency.
Awareness affects pre-sales; friction affects post-sales. Small friction can change user decisions.
Agents quickly abandon tools they can’t immediately fix or use.
Customizing tools to user preferences increases their usage.
Provide concise tool info for agent inference.
Agents can create dense, organized documentation from vast information.
New tools need more docs; newer tasks strain agents until they’re trained for them.
Beads is intuitive: 4 months of design make it easy for agents to use, with a complex CLI.
 Made agent hallucinations work with Beads; minimized friction. Doing same for Gas Town.
Hallucination squatting: exploit LLM hallucinations by registering fake domains, tricking models to download malicious files.
User experience is vital: tools must be intuitive for agents, not just well-documented.
Human skill drives machine effectiveness.
Strategies to survive and appeal to agents are vital now; more approaches exist.
Human-curated software values creativity and approval over token efficiency.
Human-curated playlists often preferred over efficient AI versions; humans beat better AIs in games; social networks may exclude AIs.
H leverizes human preference over efficiency, opening new opportunities.
Designing human teachers despite AI's rise, considering factors like cost and user preference.
Must differentiate through controllable factors despite high human element in competitive AI space.
Many inefficient high-H software will exist—perhaps yours. Good luck.
Hope offers strength in difficult times.
Fearing software that helps AIs, as AIs will soon outperform them.
Infinite software demand outpaces available resources; progress continues despite falling token costs.
Old solutions to attention now apply to new tools; virtuous cycles from efficient AI.
Design tools to match user needs; simple, iterative improvements beat expensive AI training.
Prioritize human connection in software to counter growing anti-agent sentiment and turn it into a marketing advantage.
Six levers offer survival paths; framework adapted from thermodynamics and evolution.
Stay hopeful, enjoy new software, build innovative, user-friendly tools.
Return to Gas Town soon, update on rule-breaking in news, visit gastownhall.ai and Discord.
```

_Note: This example is not really what this tool was written for but it was a silly example that popped up while I was working on things._

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

#### Packaging and signing

Likewise to building a binary release, signing and packaging that binary is a bit involved. Specifically, it requires copying both the binary and the auto-generated `mlx-swift_Cmlx.bundle` bundle in to the package "root" before calling `pkgbuild`. As mentioned above I have not done work to automate parsing out the final build folder (`/DerivedData/Docent-{SOME_RANDOM_STRING}`) from the `xcodebuild` command used to build the binary.

Below is an example shell script for automating most (but not all) of the signing, package and notarizing dance. Two things to note:

1. The five variables at the top of the script. You will need to update these per your circumstances.
2. The shell script assumes that it is in the root directory of the `Docent` repository and calls the `macos` Makefile target (described above) to build the initial binary (that will be signed and notarized).

```
ARCH=arm64
VERSION=YOUR_VERSION_NUMBER
BUILDROOT=YOUR_BUILD_PRODUCTS_RELEASE_FOLDER
DEVELOPER_ID=YOUR_APPLE_DEVELOPER_IDENTIFIER
KEYCHAIN_PROFILE=YOUR_NOTARYTOOL_PROFILE

echo "Build verion ${VERSION} for ${ARCH}"

mkdir -p dist

rm -rf .build
mkdir -p .build/pkgroot

echo "Build release"

make macos

echo "Codesign"

codesign \
    --sign ""Developer ID Application: ${DEVELOPER_ID}" \
    --options runtime \
    --timestamp \
    ${BUILDROOT}/docent

cp ${BUILDROOT}/docent .build/pkgroot/
cp -r ${BUILDROOT}/mlx-swift_Cmlx.bundle .build/pkgroot/

echo "Package build"

pkgbuild \
    --root .build/pkgroot \
    --identifier org.sfomuseum.docent \
    --version ${VERSION} \
    --install-location /usr/local/bin docent-${ARCH}-${VERSION}.pkg

echo "Product build"

productbuild \
    --package docent-${ARCH}-${VERSION}.pkg \
    --identifier org.sfomuseum.docent \
    --version ${VERSION} \
    --sign "Developer ID Installer: ${DEVELOPER_ID}" \
    dist/docent-${ARCH}-${VERSION}.pkg

rm docent-${ARCH}-${VERSION}.pkg

echo "Build complete. You will still need to submit the build for notirization:"
echo "-------------------------------------------------------------------------"
echo xcrun notarytool submit dist/docent-${ARCH}-${VERSION}.pkg --keychain-profile ${KEYCHAIN_PROFILE} --wait
```

## See also:

* https://github.com/ml-explore/mlx-swift
* https://github.com/ml-explore/mlx-swift-lm
* https://developer.apple.com/documentation/foundationmodels
