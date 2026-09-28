# Flux

A small native macOS app that turns whatever is on your clipboard into something more useful, without sending anything to the cloud.

Press a hotkey, drop or paste text, a link, an image, a PDF, or a file, and Flux figures out what it is and shows you the actions that make sense for it. Clean a tracking URL, format JSON, resize and compress an image, pull text out of a screenshot with OCR, merge PDFs, hash a file. Run one action, or chain a few together into a workflow you can save and reuse.

Everything runs on your Mac. No network calls, no accounts, no telemetry.

## What it can do

- **Text:** case changes, trim whitespace, drop blank lines, sort lines, reverse, slugify, Base64 and URL encode/decode
- **Links:** strip `utm_*` / `fbclid` / `gclid` params, make a Markdown link, generate a QR code
- **JSON:** pretty print or minify
- **Images:** convert between PNG and JPEG, compress, resize, run OCR with Apple Vision
- **PDFs:** merge several into one, or pull out a page range like `1-3, 5, 8-10`
- **Files:** SHA-256 hash

You can also string actions together. A saved "Web Ready" workflow can resize, convert to JPEG, and compress in one go, then show you how much smaller the file got.

## Install

Grab `Flux-0.1.0.dmg` from the [latest release](https://github.com/mastercoder26/newflux/releases/latest), open it, and drag Flux into Applications. On first launch right click the app and choose Open so Gatekeeper lets it run (it is ad hoc signed, not notarized).

Requires macOS 14.0 or later. Apple Silicon.

## Build from source

```sh
git clone https://github.com/mastercoder26/newflux.git
cd newflux
swift build -c release
```

The binary lands in `.build/release/Flux`. Run the tests with `swift test`.

## How it's put together

- `Flux/Core` does the actual work: content detection, the action registry, the workflow engine, and history. No SwiftUI in here.
- `Flux/Platform` talks to macOS: the floating panel, clipboard, save panels, global hotkey.
- `Flux/Features` is the SwiftUI surface: palette, action grid, preview, result, settings, workflow builder.
- `Flux/App` is the entry point and app state.
- `Tests` covers the units and a few end to end flows through the palette.

## License

MIT. See [LICENSE](./LICENSE).
