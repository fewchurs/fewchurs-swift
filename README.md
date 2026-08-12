# FeatureRequestKit

A drop-in SwiftUI feature-request board for iOS apps. Your users see what's planned, vote on
ideas, and submit their own — backed by your FeatureRequestKit account.

- iOS 17+, Swift 5.9+
- Zero third-party dependencies (`URLSession` + `Codable` + `async`/`await` only)
- Native-looking by default — matches your app's system appearance

## Installation

In Xcode: **File → Add Package Dependencies…** and enter this repository's URL, or add it to
your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/FeatureRequestKit.git", from: "1.0.0")
]
```

## Integration

Three lines. Configure once, early in your app's lifecycle, then present the board wherever
you like:

```swift
import SwiftUI
import FeatureRequestKit

@main
struct MyApp: App {
    init() {
        FeatureRequestKit.configure(apiKey: "fr_live_xxx")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

```swift
struct ContentView: View {
    @State private var isPresentingBoard = false

    var body: some View {
        Button("Feature Requests") {
            isPresentingBoard = true
        }
        .sheet(isPresented: $isPresentingBoard) {
            FeatureRequestBoardView()
        }
    }
}
```

See [`SampleApp/`](SampleApp) for a complete, runnable example (open `SampleApp.xcodeproj`
in Xcode, or regenerate it with [xcodegen](https://github.com/yonaskolb/XcodeGen) from
`SampleApp/project.yml`).

### Identifying users (optional)

If your app already has its own auth, associate votes and submissions with a known user
instead of the anonymous per-device identity:

```swift
FeatureRequestKit.identify(userId: currentUser.id, email: currentUser.email)
```

## Theming

`FeatureRequestBoardView` matches the host app's system appearance by default. Pass a theme
to `configure` to change the accent color, background, and corner radius:

```swift
FeatureRequestKit.configure(apiKey: "fr_live_xxx", theme: .midnight)
```

Two themes are included:

- `.system` (default) — `Color(.systemBackground)`, `.accentColor`, and follows the device's
  light/dark appearance
- `.midnight` — a fixed black-and-white dark theme, regardless of the device's appearance
  setting

Or build your own:

```swift
FeatureRequestTheme(background: .indigo, accent: .yellow, cornerRadius: 20)
```

## About your API key

The key you pass to `configure(apiKey:)` is a **publishable key** — it identifies your
FeatureRequestKit project, not a user or an admin. It's safe to ship inside your app binary;
it cannot be used to read data outside what the board already exposes or to perform
privileged actions on your account.

## Testing

Open `Package.swift` in Xcode and run the `FeatureRequestKit` scheme against an iOS
Simulator destination, or from the command line:

```bash
xcodebuild test -scheme FeatureRequestKit -destination 'platform=iOS Simulator,name=iPhone 17'
```

Plain `swift build` / `swift test` won't work here — this package uses UIKit-backed SwiftUI
APIs (like `Color(.systemBackground)`) that only exist when building for iOS, and macOS is
`swift build`'s default host destination.
