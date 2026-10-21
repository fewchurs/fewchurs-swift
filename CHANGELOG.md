# Changelog

## Unreleased

### Changed

- The default API is now `https://www.fewchurs.com/api/v1`. The board's own domain moved from
  `fewchurs.shop` to `fewchurs.com`; as before, the apex redirects to `www`, so requests go
  straight to the host that serves them.

## 1.1.2

### Changed

- **Fewer server requests.** The board remembers what it loaded, so closing and reopening it
  within a minute shows the list instantly without asking the server again; after that it
  still shows instantly and refreshes in the background. Board settings (branding, hidden vote
  counts, app name) are cached for five minutes, and pull to refresh reloads them.
- **Smaller pages, loaded earlier.** 15 requests per page (was 20) and 20 comments (was 50),
  which cuts the database reads behind each page by about a quarter for requests and more than
  half for comments. The next page starts loading five rows before the end of the list.
- Requests now send `X-Fewchurs-Sdk: swift/1.1.2`.

## 1.1.1

### Fixed

- The vote button in board rows is centred vertically against the row's text, instead of sitting
  at the top of rows that have a description.
- Requests now send `X-Fewchurs-Sdk: swift/1.1.1`.

## 1.1.0

The first tagged release. It brings the SDK up to date with the current Fewchurs API. Every
change is additive: code written against earlier commits still compiles.

### Fixed

- **Following and unfollowing a request works again.** The SDK expected a different response
  shape from the one the server sends, so every follow showed "Received an unexpected
  response" and was rolled back on screen. The follow had actually succeeded, so users got
  emails for something the app said had failed. The automatic follow after submitting with an
  email failed silently for the same reason.
- **Posting a comment works.** Comments were sent to an endpoint that only supports reading
  them (HTTP 405). They now go to `POST /comments`.
- A request that isn't on a loaded page (for example opened from a deep link) is fetched,
  instead of showing "Request Not Found".
- Paging no longer stops for good when the server returns an empty page with more to come
  (this happens when comments were deleted).
- Input limits match the server: titles up to 100 characters (was 80), descriptions up to 1,000
  (was 500), comments up to 1,000 and display names up to 60 (both were unlimited). Pasted text
  is no longer cut off silently.
- Server error text, HTML error pages and HTTP codes are never shown to users. Every error has
  friendly copy; technical detail appears only in Debug builds.
- An unrecognised feature status no longer breaks the whole list.

### Added

- `configure(apiKey:theme:baseURL:isSubscriber:)`. Point at staging or a local server, and report
  whether the user is a paying subscriber (shown in the dashboard).
- `identify(email:)`. The signed-in user's email pre-fills the submit form and enables one-tap
  follow.
- `FeatureRequestBoardView(title:showsRoadmap:)`. A custom title (defaults to your app's name from
  the dashboard) and an opt-in **Roadmap** tab of planned, in-progress and done requests.
- `FeatureRequestBoardView(featureId:)`. Opens the board on a single request.
- `FeatureRequestKit.productionBaseURL` and `FeatureRequestKit.sdkVersion`.
- Respects the dashboard's **Hide vote counts** setting.
- "Your request" and "You" tags on the user's own requests and comments.
- Pull to refresh on a request's detail screen.
- A privacy manifest (`PrivacyInfo.xcprivacy`).
- User-facing strings live in a String Catalog, ready for translation.

### Changed

- The default API is now `https://www.fewchurs.shop/api/v1` (was `fewchurs.vercel.app`).
- Submitting with an email creates and follows the request in one network call.
- Requests carry `X-Fewchurs-Sdk: swift/1.1.0` and `Accept-Language` headers.
- The SDK uses its own `URLSession` with a 15-second timeout. Loading, voting and following retry
  once after a dropped connection, a timeout or a 502/503/504. Creating a request or a comment
  is never retried, so it can't be duplicated.
- Vote, follow and send buttons have 44×44 pt tap targets. VoiceOver reads "Upvote, 42 votes,
  selected". Rows reflow at the largest accessibility text sizes.
- The footer reads "Powered by Fewchurs".
- Builds cleanly with strict concurrency checking and in Swift 6 language mode.

### Deprecated

- `identify(userId:email:)`. The API has no user ID, so `userId` was never used. Use
  `identify(email:)`.
