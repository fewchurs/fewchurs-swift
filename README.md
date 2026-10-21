# FeatureRequestKit

The SwiftUI SDK for [Fewchurs](https://www.fewchurs.com): a drop-in feature request board for
iOS apps. Your users see what's planned, vote on ideas, follow them, comment, and submit their own.

- iOS 17+, Swift 5.9+ (Xcode 15+)
- No third-party dependencies (`URLSession` + `Codable` + `async`/`await`)
- Native look by default: follows your app's light/dark mode and accent color
- Ships a privacy manifest

**New to Xcode?** Follow [GETTING_STARTED.md](GETTING_STARTED.md). It walks through a brand-new
app step by step and lists every error you're likely to see, with the fix.

## Installation

In Xcode: **File → Add Package Dependencies…**, paste the URL below, and choose
**Up to Next Major Version** from `1.1.0`.

```
https://github.com/fewchurs/fewchurs-swift
```

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/fewchurs/fewchurs-swift", from: "1.1.0")
]
```

The library product and module are both called `FeatureRequestKit`.

## Quick start

Configure once, when your app starts, with the API key from your Fewchurs dashboard:

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

Then show the board anywhere: a sheet, a tab, or a navigation push.

```swift
struct ContentView: View {
    @State private var showBoard = false

    var body: some View {
        Button("Suggest a feature") {
            showBoard = true
        }
        .sheet(isPresented: $showBoard) {
            FeatureRequestBoardView()
        }
    }
}
```

From UIKit, wrap it: `present(UIHostingController(rootView: FeatureRequestBoardView()), animated: true)`.

[`SampleApp/`](SampleApp) is a complete, runnable example. Open `SampleApp.xcodeproj` in Xcode
(or regenerate it with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from
`SampleApp/project.yml`) and paste your key into `SampleApp.swift`.

## Configuration

Every parameter except `apiKey` is optional.

```swift
FeatureRequestKit.configure(
    apiKey: "fr_live_xxx",
    theme: .system,                            // colors and corner radius
    baseURL: FeatureRequestKit.productionBaseURL, // the API to talk to
    isSubscriber: { Purchases.isPro }          // is the current user paying?
)
```

### Theme

The board follows the host app by default. Two themes are included, or build your own:

| Theme | Looks like |
|---|---|
| `.system` (default) | `Color(.systemBackground)`, your `.accentColor`, follows light/dark mode |
| `.midnight` | Always dark, black and white |
| `FeatureRequestTheme(background:accent:cornerRadius:)` | Your own colors and corner radius |

```swift
FeatureRequestKit.configure(apiKey: "fr_live_xxx", theme: .midnight)
```

### Subscriber flag

`isSubscriber` is called each time a user submits a request, and the answer is shown next to
that request in your dashboard. Use it to weigh ideas from paying users. Without it, `false` is sent.

### Base URL

Defaults to production, `https://www.fewchurs.com/api/v1`. Pass a different `baseURL` to point
the board at a staging or local server, for example `URL(string: "http://localhost:3000/api/v1")!`.
A plain-HTTP local server also needs `NSAllowsLocalNetworking` in your app's Info.plist.

### Identifying the user

If your app knows who is signed in, pass their email. The board then won't ask for it: it
pre-fills the email field when submitting and follows a request with one tap. If the user
typed a different email into the board before, theirs wins.

```swift
FeatureRequestKit.identify(email: currentUser.email)   // after sign-in
FeatureRequestKit.identify(email: nil)                 // after sign-out
```

`identify` and `configure` can be called in any order. `identify(userId:email:)` still compiles but
is deprecated: the API has no user ID (votes and follows belong to the device), so `userId` was
never sent anywhere.

## Board options

```swift
FeatureRequestBoardView(
    title: "Ideas",        // optional; defaults to your app's name from the dashboard
    showsRoadmap: true     // optional; adds a Roadmap tab
)
```

- **Title.** Without one, the board uses your app's name from the dashboard, then
  "Feature Requests" while that loads.
- **Roadmap.** `showsRoadmap: true` adds a third tab listing planned, in-progress and done
  requests, most-voted first. Off by default.
- **Open one request.** `FeatureRequestBoardView(featureId: "abc123")` opens the board with that
  request already showing, for deep links and notifications. Back goes to the full board.

## What's controlled from the dashboard

These need no code. The board picks up changes within five minutes, or straight away when the user pulls the list down to refresh:

- **Hide vote counts** (app settings). The vote buttons show no numbers, but voting still works.
- **"Powered by Fewchurs" line.** It shows on the Free plan and disappears on Starter and Pro.
- **How many requests the board lists.** The board shows an app's first 5 requests on Free,
  its first 200 on Starter, and all of them on Pro. Newer requests are still saved and appear
  in your dashboard. One a user just submitted shows on their board straight away, but once the
  app is over its limit it leaves the list on the next refresh. They can still open it with
  `FeatureRequestBoardView(featureId:)`.
- **App name.** Used as the board's default title.

## Limits

The board loads 15 requests at a time (20 comments on a request) and fetches the next page as
the user nears the end of the list. Closing and reopening the board within a minute reuses what
was loaded instead of asking the server again.

Each device can submit 15 requests and post 10 comments a day; the board tells the user kindly
when they hit either. Votes and follows aren't limited. Titles are 3–100 characters,
descriptions up to 1,000, comments up to 1,000 and display names up to 60. A counter appears
near each limit.

## Privacy

The package includes `PrivacyInfo.xcprivacy`. It declares, all for app functionality and none
for tracking:

- **Other user content:** request titles and descriptions, comments, and the optional display
  name shown on a comment. Not linked to identity.
- **Email address:** only when the user chooses to follow a request. Linked to identity.
- **Device ID:** a random UUID kept in the Keychain so votes work without an account. Not the
  IDFA or IDFV. Not linked to identity.

No required-reason APIs are used. Xcode merges this into your app's privacy report. Review it
against your own app's practices before submitting.

## About the API key

The key you pass to `configure(apiKey:)` is a **publishable key**. It identifies your Fewchurs
app, not a user or an admin, so it's safe to ship inside your app. It can only do what the board
does (list, vote, follow, comment, submit), not read private data or change settings.

## Errors

Users only ever see short, friendly messages, such as "Couldn't reach the server. Check your
connection and try again." In Debug builds an extra grey line shows the technical detail (for
example `HTTP 502` or a decoding problem), to help during integration. Release builds hide it.
[GETTING_STARTED.md](GETTING_STARTED.md#if-something-goes-wrong) lists every message and what
to do about it.

## Testing the package

Open `Package.swift` in Xcode and run the `FeatureRequestKit` scheme on an iOS Simulator, or:

```bash
xcodebuild test -scheme FeatureRequestKit -destination 'platform=iOS Simulator,name=iPhone 17'
```

Plain `swift build` / `swift test` won't work: the package uses UIKit-backed SwiftUI APIs that
only exist when building for iOS, and macOS is SwiftPM's default destination.

The tests use an in-process stub server (`Tests/…/Support/StubServer.swift`), so they need no
network. There's also an opt-in **live contract test** that calls the real API and decodes every
response. Use a key for a test app:

```bash
TEST_RUNNER_FEWCHURS_CONTRACT_API_KEY=fr_live_xxx xcodebuild test -scheme FeatureRequestKit -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing FeatureRequestKitTests/LiveContractTests
```

It votes and follows, then undoes both. Add `TEST_RUNNER_FEWCHURS_CONTRACT_ALLOW_WRITES=1` to
also create one request and one comment. Delete those from the dashboard afterwards.

## Changes

See [CHANGELOG.md](CHANGELOG.md).
