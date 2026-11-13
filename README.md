# HarmonyFlow

Unified, coordinator-driven navigation for SwiftUI on iOS and macOS. Each feature defines its own screen types; lightweight coordinators own the navigation state; container views (`HarmonyStack`, `HarmonyTabs`, `HarmonySplit`) render it. Pushes, modals, bottom sheets, tabs, split views, async "present-for-result", and opt-in state restoration all speak the same vocabulary.

- **Requirements:** iOS 18+, macOS 15+, Swift 6
- **No UIKit fallbacks**, no hard-coded dimensions, `async/await` throughout.

## Installation

```swift
.package(url: "https://github.com/ios-tooling/HarmonyFlow.git", from: "0.2.0")
```

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "HarmonyFlow", package: "HarmonyFlow")
])
```

Import it as `import HarmonyFlow`. Releases are tagged; use `branch: "main"` to follow unreleased work.

## The core idea

You define screen types by conforming to **`HarmonyDestination`** — typically one enum per feature/framework. Each case knows how to draw itself, given a coordinator. The framework boxes any destination into a single concrete `HarmonyScreen` value, so destinations from **different, independent frameworks coexist in the same coordinator/stack** — there is no central enum that has to know them all.

```swift
enum Screen: HarmonyDestination {
    case home, detail, settings

    var id: String { "\(self)" }

    func body(configuration: HarmonyScreenConfiguration) -> some View {
        switch self {
        case .home:
            Button("Show detail") { configuration.coordinator.push(Screen.detail) }
        case .detail:
            Button("Settings") { configuration.coordinator.partialModal(Screen.settings) }
        case .settings:
            Button("Done") { configuration.coordinator.dismiss() }
        }
    }
}
```

> **Note on shorthand:** navigation methods take `any HarmonyDestination`, so leading-dot syntax (`push(.detail)`) can't infer the type — qualify the case name (`push(Screen.detail)`).

Create a coordinator with a root screen and hand it to a `HarmonyStack`:

```swift
struct ContentView: View {
    @State private var coordinator = HarmonyCoordinator(Screen.home)
    var body: some View { HarmonyStack(coordinator) }
}
```

## Reaching the coordinator

Every screen `body` receives a `HarmonyScreenConfiguration` with `.coordinator`. Deeper subviews can pull the same coordinator from the environment instead of threading it down — the coordinator is a single non-generic type, so a view in *any* framework can reach it without naming an app-specific screen type:

```swift
struct DeepButton: View {
    @HarmonyCoordinated private var coordinator
    var body: some View { Button("Back") { coordinator.dismiss() } }
}
```

`@HarmonyCoordinated` traps if no coordinator is in the environment; use its projected value (`$coordinator`) for optional access (e.g. a standalone `#Preview`). The underlying `@Environment(HarmonyCoordinator.self)` works too.

## Modular apps & multiple frameworks

Because the coordinator tree is built on the erased `HarmonyScreen`, a feature framework imports **only HarmonyFlow** and defines its own destinations; it never imports its siblings. Any screen can push or present any other:

```swift
// in ProfileKit — knows nothing about other features
coordinator.push(ProfileScreen.editor)
coordinator.push(Screen.settings)   // a different framework's type, same stack
```

Type erasure solves *coexistence*. Cross-feature *navigation intent* still needs a contract — keep features decoupled by inverting the dependency (inject an `onOpenSettings: () -> Void` the app fills in) or by routing through your **app target as the composition root**, the one place that imports everything and maps routes to concrete screens.

## Navigation vocabulary

```swift
coordinator.push(Screen.detail)            // onto the navigation stack
coordinator.partialModal(Screen.settings)  // sheet, .medium detent by default
coordinator.bottomSheet(Screen.filters)    // interactive overlay card (see below)
coordinator.fullScreenModal(Screen.editor) // full-screen cover (sheet on macOS)

coordinator.dismiss()              // go back one: pop a push, or dismiss a presentation root
coordinator.dismissStack()         // dismiss the entire presented flow this screen lives in
coordinator.dismissTopFlow()       // from the presenting side: dismiss only the frontmost presented flow
coordinator.pop(to: Screen.home)   // pop back to a specific screen
coordinator.popToRoot()            // pop all pushes
coordinator.collapse()             // back to a pristine root: pop everything + drop presentations
```

`dismiss()` is always "go back one step" — a screen never needs to know *how* it was presented.

### Showing while something is presented

- A presentation belongs to the coordinator it was shown from.
- `push` on a coordinator that is presenting a modal adds to that coordinator's own path, beneath the modal. Push on `coordinator.topCoordinator` to push inside the presented flow.
- A coordinator presents one modal at a time, so a second `partialModal` / `fullScreenModal` from the same coordinator replaces the first. Present from the presented flow's coordinator to stack them.
- A bottom sheet stays up beneath a modal presented from the same coordinator.
- Modals take turns going on screen. UIKit refuses a sheet or cover requested while another modal transition is still in flight, so one requested then is held until that transition has had time to finish (up to about a second), then shown. The coordinator's state changes at once; the screen follows. Pushes, bottom sheets and dismissals are not held.

## Per-presentation configuration

`show(_:config:)` is the general form; the helpers above are shorthands for it. Configure detents and dismissal per presentation:

```swift
coordinator.show(Screen.filters, config: .init(
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
- Tapping the dimmed scrim dismisses the sheet (unless `isInteractiveDismissDisabled` is set).

## Present-for-result

Modal flows can return a value with `async/await`. Any dismissal that doesn't call `finish` (swipe, `dismiss()`, replacement, or a dismissed parent flow) resumes the caller with `nil`:

```swift
// presenter
let picked: Color? = await coordinator.present(ColorPickerScreen.picker)

// inside the presented screen
configuration.coordinator.finish(returning: chosenColor)
```

The result type is fixed at the call site (erasure means it can't be tied to the screen statically); a type mismatch resolves to `nil`.

## Tabs

Conform a tab enum to `HarmonyTab` (each case supplies a `rootScreen` and a `label`), then drive it with `HarmonyTabs`:

```swift
enum AppTab: HarmonyTab {
    case home, settings
    var rootScreen: any HarmonyDestination { self == .home ? Screen.home : Screen.settings }
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
tabs.show(Screen.account, in: .settings)   // switch tab, then push
tabs.collapse()                            // reset the selected tab to its root
tabs.dismissTopFlow(in: .settings)         // dismiss only the frontmost flow presented in that tab
tabs.topScreen                             // the frontmost screen, whichever tab presented it
tabs.isTabBarHidden = true                 // animated hide/show (iOS)
```

Sheets and covers are drawn over the whole window, whichever tab presented them, so what one tab has presented affects the others (observed on iOS 26 and 27):

- Selecting another tab in code (`tabs.selectedTab = …`) leaves a sheet the earlier tab presented on screen, over the newly selected tab. It still belongs to the earlier tab's coordinator; `tabs.topScreen` reports what is actually frontmost.
- `tabs.show` does not leave it there: a push or bottom sheet shown in one tab first closes any modal another tab is presenting (a `present` caller waiting on it resumes with `nil`).
- A modal shown in another tab replaces it as well, through SwiftUI: it takes the earlier tab's sheet down, then presents the new modal, and the earlier tab's coordinator drops the sheet.

## Split views

`HarmonySplitCoordinator` backs 2- or 3-column layouts; columns navigate independently with the full vocabulary above. Columns may hold destinations of different types.

```swift
let split = HarmonySplitCoordinator(sidebar: Screen.home, detail: Screen.settings)   // add content: for 3 columns
HarmonySplit(split)

split.showDetail(Screen.account)   // selection-style: replaces the detail column's stack
```

## Reading the stack

What a coordinator is showing is readable as values, without encoding its state. The properties are observed, so a view or `withObservationTracking` that reads them updates when the stack changes.

```swift
coordinator.root                  // the screen at the bottom of the stack
coordinator.path                  // the screens pushed above the root, bottom to top
coordinator.presentedModal        // the modal flow's coordinator, if any
coordinator.presentedBottomSheet  // the bottom sheet's coordinator, if any
coordinator.topCoordinator        // the coordinator of the frontmost flow
coordinator.screens               // every screen showing, from the root up
coordinator.topScreen             // the frontmost screen

if let screen = coordinator.topScreen.destination as? Screen { … }

tabs.topCoordinator               // under tabs: the frontmost flow, whichever tab presented it
tabs.topScreen                    // … and its top screen
```

`screens` lists the coordinator's own stack, then its bottom sheet's screens, then its modal's — the order they sit on screen. Under tabs, read one tab through `tabs.coordinator(for: .home).screens` and the frontmost screen across tabs through `tabs.topScreen`: a modal covers every tab, so a tab presenting one comes before the selected tab. A tab's bottom sheet is hosted above the tab bar but still reported by the tab that presented it; `tabs.presentedBottomSheet` is that sheet whichever tab presented it. These values are the coordinator's state. The screen follows them, though not instantly: a sheet or cover that is waiting its turn (see "Showing while something is presented") is listed before it is on screen.

## State persistence & deep linking

`HarmonyScreen` is always `Codable`, so the save/restore API is always available. Because destinations are type-erased, persistence needs a way to recover the concrete type on decode: register each `Codable` destination type once (e.g. at launch). Each framework registers its own — no central list.

```swift
HarmonyScreenRegistry.register(Screen.self, forKey: "App.Screen")
HarmonyScreenRegistry.register(ProfileScreen.self, forKey: "Profile.Screen")

let data = try coordinator.encodedState()              // save (whole presentation tree)
let coordinator = try HarmonyCoordinator(restoring: data)   // restore at launch
```

`encodedState()` / `init(restoring:)` work the same on `HarmonyTabCoordinator` and `HarmonySplitCoordinator` (their `Tab` must also be `Codable`). A screen whose type wasn't registered throws on encode/decode — restore paths treat that as "skip".

For deep links, parse the URL into destinations (your code) and hand the path over:

```swift
coordinator.replacePath([Screen.account, Screen.orders, Screen.order(id)])
```

## Accessing container coordinators safely

A screen shared between a tab root and a split root may not have a given container in its environment. Fetch container coordinators **optionally** unless a screen is exclusive to one container:

```swift
@Environment(HarmonyTabCoordinator<AppTab>.self) private var tabs: HarmonyTabCoordinator<AppTab>?
```

The per-`HarmonyStack` `HarmonyCoordinator` is always present, so non-optional access to it (e.g. via `@HarmonyCoordinated`) is safe.

## License

See repository.
