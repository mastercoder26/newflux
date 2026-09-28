# Flux
> Universal local transformation palette for macOS.

![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/mastercoder26/newflux?include_prereleases)
![GitHub last commit](https://img.shields.io/github/last-commit/mastercoder26/newflux)
![GitHub issues](https://img.shields.io/github/issues-raw/mastercoder26/newflux)
![GitHub pull requests](https://img.shields.io/github/issues-pr/mastercoder26/newflux)
![GitHub](https://img.shields.io/github/license/mastercoder26/newflux)

Flux is a native macOS transformation palette that turns text, URLs, images, PDFs, and files into useful outputs without leaving your keyboard. A user invokes a global keyboard shortcut, pastes or drops content into a floating panel, Flux automatically detects the content type, and presents only compatible local actions.

Users can also chain compatible transformations into reusable sequential workflows (e.g. Resize -> Convert to JPEG -> Compress), inspect real-time progress, review side-by-side file size savings, and export or copy results instantly. Everything executes locally on your Mac with zero network spend or external API calls.

## Table of Contents
- [Flux](#flux)
- [Quickstart / Demo](#quickstart--demo)
- [Installation](#installation)
- [Usage](#usage)
- [Development](#development)
- [Contributing](#contributing)
- [Release History](#release-history)
- [License](#license)
- [Meta](#meta)

## Quickstart / Demo
[(Back to top)](#table-of-contents)

1. Launch Flux and press `Option + Space` from anywhere on macOS.
2. Paste clipboard contents or drag any file into the floating palette.
3. Flux detects whether the input is Text, JSON, a URL, an Image, a PDF, or arbitrary files.
4. Select a compatible action (e.g. Clean URL, Extract Text via OCR, Format JSON, Merge PDFs).
5. Preview the result, copy to clipboard, or save to disk.

```text
Clipboard / Drop / File
          |
          v
   ContentDetector
          |
          v
    ActionRegistry
          |
     compatible actions
          |
          v
     Action Engine
          |
    +-----+---------+
    |               |
single action   workflow
                    |
                    v
              WorkflowRunner
                    |
                    v
                 Result
                    |
        +-----------+---------+
        v           v         v
       Copy        Save     Continue
```

## Installation
[(Back to top)](#table-of-contents)

### Requirements

- macOS 14.0 or higher
- Apple Silicon or Intel Mac
- Xcode 15+ or Swift 5.9+ toolchain

### Build from Source

```sh
git clone https://github.com/mastercoder26/newflux.git
cd flux
swift build -c release
```

The compiled binary will be located at `.build/release/Flux`.

## Usage
[(Back to top)](#table-of-contents)

### Core Features

- **Global Shortcut**: Press `Option + Space` (configurable in Settings) to summon the floating palette over any active window.
- **Universal Drop & Paste**: Drag-and-drop files, images, PDFs, or paste clipboard contents with `Command + V`.
- **Automatic Content Detection**:
  - URLs: Strips marketing query parameters (`utm_*`, `fbclid`, `gclid`), generates QR codes, outputs Markdown links.
  - JSON: Validates formatting, pretty-prints with sorted keys, or minifies payloads.
  - Text: Cleans extra whitespace, collapses blank lines, transforms casing (uppercase, lowercase, title case), sorts lines, reverses text, Base64 and URL percent encode/decode, and slugifies into URL-safe slugs.
  - Images: Resizes with aspect ratio preservation, converts between PNG and JPEG, compresses JPEG with configurable quality, and performs offline OCR using Apple Vision.
  - PDFs: Merges multiple documents into one, extracts specified page ranges (e.g. `1-3, 5, 8-10`).
  - Files: Computes incremental SHA-256 digests.
- **Workflow Engine**: Chain compatible actions into reusable pipelines (such as `Web Ready: Resize -> Convert JPEG -> Compress`). Validates compatibility before execution and displays real-time progress.
- **Local History**: Records transformation summaries locally without duplicating large user files.

### Workflow Example

```text
Input: High-resolution PNG Screenshot
  |
  +-> Step 1: Resize Image (Width: 1600 px, preserve aspect ratio)
  |
  +-> Step 2: Convert to JPEG (Quality: 85%)
  |
  +-> Step 3: Compress JPEG (Quality: 80%)
  |
Output: Web-optimized JPEG (-68.4% file size reduction)
```

### Privacy Statement

All processing is strictly local. Flux makes no network requests, does not contact remote servers or third-party APIs, and contains no telemetry or analytics. Your files, clipboard data, and credentials never leave your Mac.

## Development
[(Back to top)](#table-of-contents)

### Architecture

The codebase enforces strict separation of concerns across layers:

- `Flux/Core`: Core transformation algorithms, content detection, action registry, workflow engine, and history store. Completely independent of SwiftUI.
- `Flux/Platform`: macOS system integrations including `NSPanel` floating window controller, `NSPasteboard` clipboard service, `NSSavePanel` export service, and global hotkeys.
- `Flux/Features`: SwiftUI interfaces including palette coordinator, previews, action grid, workflow builder, progress indicators, history, and settings.
- `Flux/App`: Application entry point, AppKit application delegate, and state management.
- `Tests`: Unit and end-to-end acceptance tests.

### Build and Test Commands

```sh
# Resolve dependencies
swift package resolve

# Run full test suite
swift test

# Build executable
swift build

# Run application
swift run Flux
```

### Known Limitations

- OCR requires macOS language data installed for non-English character recognition.
- Multiple file operations operate on batches of the same general media family (e.g. merging PDFs).

## Contributing
[(Back to top)](#table-of-contents)

Contributions are welcome. To propose a change:

1. Fork it (<https://github.com/mastercoder26/newflux/fork>)
2. Create your feature branch (`git checkout -b feature/newAction`)
3. Commit your changes (`git commit -m 'feat: add new action'`)
4. Push to the branch (`git push origin feature/newAction`)
5. Open a new Pull Request

Please make sure all tests pass (`swift test`) and conventional commits are followed before opening a PR.

## Release History
[(Back to top)](#table-of-contents)

* 0.1.0
    * Complete native macOS implementation with 16 local transformations
    * Multi-step workflow builder and runner
    * Floating AppKit panel with SwiftUI vibrancy
    * Comprehensive automated test suite
* 0.0.1
    * Initial repository scaffolding

## License
[(Back to top)](#table-of-contents)

Distributed under the MIT License. See [`LICENSE`](./LICENSE) for more information.

## Meta
[(Back to top)](#table-of-contents)

Sreeharsha Kannegundla – [@Creator101-commits](https://github.com/Creator101-commits)

Project link: [https://github.com/mastercoder26/newflux](https://github.com/mastercoder26/newflux)
