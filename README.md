# HarmonyFlow

Unified, coordinator-driven navigation for SwiftUI on iOS and macOS. One screen type per app describes every destination; lightweight coordinators own the navigation state; container views (`HarmonyStack`, `HarmonyTabs`, `HarmonySplit`) render it. Pushes, modals, bottom sheets, tabs, split views, async "present-for-result", and opt-in state restoration all speak the same vocabulary.

- **Requirements:** iOS 18+, macOS 15+, Swift 6
- **No UIKit fallbacks**, no hard-coded dimensions, `async/await` throughout.

## Installation

```swift
.package(url: "https://github.com/ios-tooling/HarmonyFlow.git", branch: "main")
```

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "HarmonyFlow", package: "HarmonyFlow”)
])
```

Import it as `import HarmonyFlow`. (No versioned release is tagged yet; pin to a commit if you need stability.)

## The core idea

You define **one `HarmonyScreen` enum for the whole app**. Each case knows how to draw itself, given a coordinator. This single-type design is what makes cross-cutting navigation ("switch to the Settings tab and push the Account screen") trivially expressible, and it's the constraint the rest of the framework is built around.

```swift
enum Screen: HarmonyScreen {
    case home, detail, settings

    var id: String { "\(self)" }

    func body(configuration: HarmonyCoordinator<Self>.ScreenConfiguration) -> some View {
        switch self {
        case .home:
            Button("Show detail") { configuration.coordinator.push(.detail) }
        case .detail:
            Button("Settings") { configuration.coordinator.partialModal(.settings) }
        case .settings:
            Button("Done") { configuration.coordinator.dismiss() }
        }
    }
}
```

Create a coordinator with a root screen and hand it to a `HarmonyStack`:

```swift
struct ContentView: View {
    @State private var coordinator = HarmonyCoordinator(Screen.home)
    var body: some View { HarmonyStack(coordinator) }
}
```

## Reaching the coordinator

Every screen `body` receives a `ScreenConfiguration` with `.coordinator`. Deeper subviews can pull the same coordinator from the environment instead of threading it down:

```swift
struct DeepButton: View {
    @Environment(HarmonyCoordinator<Screen>.self) private var coordinator
    var body: some View { Button("Back") { coordinator.dismiss() } }
}
```

## Navigation vocabulary

```swift
coordinator.push(.detail)            // onto the navigation stack
coordinator.partialModal(.settings)  // sheet, .medium detent by default
coordinator.bottomSheet(.filters)    // interactive overlay card (see below)
coordinator.fullScreenModal(.editor) // full-screen cover (sheet on macOS)

coordinator.dismiss()        // go back one: pop a push, or dismiss a presentation root
coordinator.dismissStack()   // dismiss the entire presented flow this screen lives in
coordinator.pop(to: .home)   // pop back to a specific screen
coordinator.popToRoot()      // pop all pushes
coordinator.collapse()       // back to a pristine root: pop everything + drop presentations
```

`dismiss()` is always "go back one step" — a screen never needs to know *how* it was presented.

## Per-presentation configuration

`show(_:config:)` is the general form; the helpers above are shorthands for it. Configure detents and dismissal per presentation:

```swift
coordinator.show(.filters, config: .init(
    action: .bottomSheet,
    detents: [.fraction(0.25), .medium, .fraction(0.85)],
    isInteractiveDismissDisabled: true
))
```

`HarmonyDetent` (`.medium`, `.large`, `.fraction(_)`, `.height(_)`) is platform-neutral — it maps to `PresentationDetent` on iOS and is honored by HarmonyFlow's own bottom-sheet renderer on both platforms.

## Bottom sheets

Bottom sheets are **not** system sheets — they're draggable overlay cards rendered by HarmonyFlow, so the content behind them stays fully interactive (Maps / Apple Music style) and they persist while modals appear over them. Rules:

- A bottom sheet attaches to its **presentation context** (its stack, modal, or — under tabs — the tab bar layer), rendering above that context's chrome.
- There is **one** bottom sheet per context; presenting a new one replaces the old. Bottom sheets never stack on each other.

## Present-for-result

Modal flows can return a value with `async/await`. Any dismissal that doesn't call `finish` (swipe, `dismiss()`, replacement) resumes the caller with `nil`:

```swift
// presenter
let picked: Color? = await coordinator.present(.colorPicker)

// inside the presented screen
configuration.coordinator.finish(returning: chosenColor)
```

The result type is fixed at the call site (the single-enum design means it can't be tied to the screen statically); a type mismatch resolves to `nil`.

## Tabs

Conform a tab enum to `HarmonyTab` (each case supplies a `rootScreen` and a `label`), then drive it with `HarmonyTabs`:

```swift
enum AppTab: HarmonyTab {
    case home, settings
    var rootScreen: Screen { self == .home ? .home : .settings }
    var label: some View {
        switch self {
        case .home: Label("Home", systemImage: "house")
        case .settings: Label("Settings", systemImage: "gear")
        }
    }
}

struct RootView: View {
    @State private var tabs = HarmonyTabCoordinator(selected: AppTab.home)
    var body: some View { HarmonyTabs(tabs) }
}
```

Each tab keeps its own navigation stack across switches. Navigate across tabs from anywhere via `@Environment(HarmonyTabCoordinator<AppTab>.self)`:

```swift
tabs.show(.account, in: .settings)   // switch tab, then push
tabs.collapse()                      // reset the selected tab to its root
tabs.isTabBarHidden = true           // animated hide/show (iOS)
```

## Split views

`HarmonySplitCoordinator` backs 2- or 3-column layouts; columns navigate independently with the full vocabulary above.

```swift
let split = HarmonySplitCoordinator(sidebar: .home, detail: .settings)   // add content: for 3 columns
HarmonySplit(split)

split.showDetail(.account)   // selection-style: replaces the detail column's stack
```

## State persistence & deep linking

Persistence is **opt-in**: conform your `Screen` (and, for containers, your `Tab`) to `Codable` and the save/restore API appears automatically. Non-`Codable` screens are unaffected — the `HarmonyScreen` protocol is never changed.

```swift
let data = try coordinator.encodedState()                 // save (whole presentation tree)
let coordinator = try HarmonyCoordinator<Screen>(restoring: data)   // restore at launch
```

`encodedState()` / `init(restoring:)` work the same on `HarmonyTabCoordinator` and `HarmonySplitCoordinator`.

For deep links, parse the URL into screens (your code) and hand the path over:

```swift
coordinator.replacePath([.account, .orders, .order(id)])
```

## Accessing container coordinators safely

A screen shared between a tab root and a split root may not have a given container in its environment. Fetch container coordinators **optionally** unless a screen is exclusive to one container:

```swift
@Environment(HarmonyTabCoordinator<AppTab>.self) private var tabs: HarmonyTabCoordinator<AppTab>?
```

The per-`HarmonyStack` `HarmonyCoordinator` is always present, so non-optional access to it is safe.

## License

See repository.
