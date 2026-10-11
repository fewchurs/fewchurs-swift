# Try Fewchurs in a new iPhone app

This guide takes you from nothing to a working feature request board on an iPhone simulator.
You don't need to know Swift. You will copy and paste two small pieces of code.

It takes about 15 minutes.

---

## What you need

- A Mac with **Xcode** installed (free from the Mac App Store). Xcode 15 or newer.
- A **Fewchurs account** at [fewchurs.shop](https://www.fewchurs.shop) with an app added to it.

---

## Step 1: Copy your API key

1. Sign in at [fewchurs.shop](https://www.fewchurs.shop).
2. Open your app in the dashboard and copy its **API key**. It starts with `fr_live_`.
3. Keep it somewhere handy. You'll paste it in Step 4.

> The key is safe to put inside your app. It can only do what the board does: show requests,
> vote, comment and suggest. It can't change your settings.

---

## Step 2: Make a new app in Xcode

1. Open Xcode and choose **File → New → Project…**
2. At the top, pick **iOS**. Then pick **App** and click **Next**.
3. Fill in the form:
   - **Product Name:** anything, for example `MyTestApp`
   - **Interface:** `SwiftUI`
   - **Language:** `Swift`
   - Leave the rest as it is.
4. Click **Next**, choose a folder (the Desktop is fine) and click **Create**.

**Check the iOS version.** The board needs iOS 17 or newer.

1. Click the blue project icon at the very top of the left sidebar.
2. Under **TARGETS**, click your app.
3. Open the **General** tab and find **Minimum Deployments**.
4. If it says something lower than **17.0**, change it to **17.0**.

---

## Step 3: Add the Fewchurs package

1. In Xcode choose **File → Add Package Dependencies…**
2. In the search box at the top right, paste:

   ```
   https://github.com/fewchurs/fewchurs-swift
   ```

3. Next to **Dependency Rule**, choose **Up to Next Major Version** and type `1.1.0`.
4. Click **Add Package**. Wait for it to download.
5. A second window asks which target gets **FeatureRequestKit**. Make sure your app is chosen
   in the **Add to Target** column, then click **Add Package** again.

You'll now see **Package Dependencies → fewchurs-swift** at the bottom of the left sidebar.

> **Testing a version that isn't published yet?** If you have the package folder on your Mac
> (for example `~/FeatureRequestKit`), use **File → Add Package Dependencies… → Add Local…**,
> pick that folder and click **Add Package**. Everything else in this guide is the same.

---

## Step 4: Paste the code

Your new project has two Swift files in the left sidebar. Replace everything in each one.

### File 1: `MyTestAppApp.swift`

This file is named after your app. If you called it `MyTestApp`, it's `MyTestAppApp.swift`.
Replace all of its contents with the code below.

- Put your **own** API key from Step 1 between the quotes.
- If your app isn't called `MyTestApp`, change `MyTestAppApp` on the `struct` line to match
  the file name (without `.swift`).

```swift
import SwiftUI
import FeatureRequestKit

@main
struct MyTestAppApp: App {
    init() {
        FeatureRequestKit.configure(apiKey: "fr_live_paste_your_key_here")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### File 2: `ContentView.swift`

Replace all of its contents with:

```swift
import SwiftUI
import FeatureRequestKit

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

---

## Step 5: Run it

1. At the top of Xcode, next to the ▶ button, pick an **iPhone** simulator (for example
   *iPhone 17*). Don't pick a Mac or "Any iOS Device".
2. Press ▶ (or **⌘R**).
3. The simulator opens and shows a **Suggest a feature** button. Tap it.

You should see your board with **Top** and **New** tabs. If your app has no requests yet, it
says **No Feature Requests Yet**. That's normal.

---

## Step 6: Try everything

| Try this | What should happen |
|---|---|
| Tap **+** (top right), type a title, tap **Submit** | Your request appears at the top with a **Your request** tag |
| Submit again, this time with your email, then tap that request | You're already **following** it: the bell is filled in |
| Tap the **▲** box on any request | The number goes up by one and the box fills in. Tap again to undo |
| Open a request and tap the **bell** | The first time, it asks for your email. Then the bell fills in. Tap again to unfollow |
| Open a request and write a comment | It asks for a name once (you can skip), then your comment appears with a **You** tag |
| Pull the list down | It refreshes |
| In your Fewchurs dashboard, open your app's **Settings**, turn on **Hide vote counts**, then close and reopen the board | The ▲ boxes show no numbers, but voting still works |

**Optional extras.** Each is a small change to the code from Step 4.

- **A Roadmap tab** (planned, in progress and done requests). In `ContentView.swift`, change
  `FeatureRequestBoardView()` to:

  ```swift
  FeatureRequestBoardView(showsRoadmap: true)
  ```

- **Dark theme.** In your app file, change the `configure` line to:

  ```swift
  FeatureRequestKit.configure(apiKey: "fr_live_…", theme: .midnight)
  ```

- **Mark paying users.** If your app has subscriptions, the dashboard can show which ideas
  came from paying users:

  ```swift
  FeatureRequestKit.configure(apiKey: "fr_live_…", isSubscriber: { /* return true for paying users */ false })
  ```

- **Skip the email question.** If your app already knows the user's email:

  ```swift
  FeatureRequestKit.identify(email: "jane@example.com")
  ```

---

## If something goes wrong

### Errors in Xcode (the app won't build)

Xcode shows these in red, next to the code or in the list on the left (⌘5).

| What Xcode says | What it means | How to fix it |
|---|---|---|
| `No versions of 'fewchurs-swift' match the requirement 1.1.0..<2.0.0` | Version 1.1.0 hasn't been published yet. | Until it is, use **Add Local…** (see the tip in Step 3). First remove the old one: blue project icon → **PROJECT** → **Package Dependencies** → select it → **−**. |
| `compiling for iOS 16.0, but module 'FeatureRequestKit' has a minimum deployment target of iOS 17.0` | Your app is set to support iPhones older than the board does. | Set **Minimum Deployments** to **17.0** (see the end of Step 2). |
| `No such module 'FeatureRequestKit'` | The package was downloaded but isn't connected to your app. | Click the blue project icon → **TARGETS** → your app → **General** → **Frameworks, Libraries, and Embedded Content** → **+** → choose **FeatureRequestKit** → **Add**. |
| `Cannot find 'FeatureRequestKit' in scope` or `Cannot find 'FeatureRequestBoardView' in scope` | A file is missing the `import FeatureRequestKit` line. | Add `import FeatureRequestKit` near the top of that file, under `import SwiftUI`. |
| `'main' attribute can only apply to one type in a module` or `Invalid redeclaration of 'ContentView'` | Some code was pasted twice, or into the wrong file. | Each file should contain only the code shown for it in Step 4. Delete anything else. |
| Lots of errors about `UIKit`, `systemBackground` or `macOS` | You're building for a Mac instead of an iPhone. | Pick an **iPhone** simulator next to the ▶ button (Step 5). If you made a *Multiplatform* project, start again and pick **iOS → App** in Step 2. |
| `Package Resolution Failed` / can't download | Xcode couldn't reach GitHub. | Check your internet connection, then **File → Packages → Reset Package Caches** and try again. |

### Messages inside the app

| What the app shows | What it means | How to fix it |
|---|---|---|
| **This app's API key is invalid. Please contact the developer.** | The key in `configure` is wrong, still the placeholder, or turned off. | Copy the key again from your dashboard (Step 1) and paste it exactly, keeping the quotes. |
| **Couldn't reach the server. Check your connection and try again.** | The phone or simulator is offline, or the server took too long to answer. | Check your Mac's internet connection and tap **Retry**. |
| **You've reached today's limit for this. Please try again tomorrow.** | Each device can submit 15 requests and 10 comments a day. | Wait until tomorrow. On a simulator you can start fresh with **Device → Erase All Content and Settings…** (this deletes everything on that simulator). |
| **This board isn't taking new requests right now.** | Your account's plan limit was reached. | Check your plan in the Fewchurs dashboard. |
| **Something went wrong on our side. Please try again in a moment.** | The Fewchurs server had a problem. | Wait a minute and tap **Retry**. If it keeps happening, contact Fewchurs support. |
| **Received an unexpected response. Please try again later.** | The app and the server disagree about something. | Make sure you're on the latest package version: **File → Packages → Update to Latest Package Versions**. |
| **Request Not Found** | That request was deleted. | Nothing to fix. Go back to the list. |
| The app **crashes** as soon as you open the board, and Xcode says `FeatureRequestBoardView was presented before FeatureRequestKit.configure(apiKey:) was called` | The `configure` line is missing or never runs. | Make sure your app file looks exactly like File 1 in Step 4, including the `init()` part. |

**Small grey text under an error.** While you run from Xcode, some errors show a second, smaller
line, such as `HTTP 502`. That's extra detail for developers. People who download your app from
the App Store never see it.

### Good to know

- **Votes belong to the device, not a person.** Your simulator and your own iPhone count as two
  different voters. That's expected.
- The **"Powered by Fewchurs"** line at the bottom shows on the Free and Starter plans. It
  disappears by itself on Pro. You don't need to change any code.
- Your feature requests, votes and comments are real. Anything you create while testing shows
  up in your dashboard, and you can delete it there.
