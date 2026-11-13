# AGENTS.md — HarmonyFlow

Operational guide for coding agents working in this repository. Read this before changing navigation behavior; the architecture has a few load-bearing invariants that aren't obvious from any single file.

The Swift module / library product / target are all named **`HarmonyFlow`** (`import HarmonyFlow`). The public type names are all `Harmony…` (`HarmonyCoordinator`, `HarmonyScreen`, `HarmonyStack`, …).

## What this package is

A SwiftUI navigation framework for iOS 18+ / macOS 15+. Screens are **type-erased**: each feature conforms its own type to the `HarmonyDestination` protocol, and those get boxed into a single concrete `HarmonyScreen` struct that the whole coordinator tree is built on — so destinations from independent frameworks coexist in one stack, with no central enum. `@Observable` coordinator classes hold navigation state; container views render it. See `README.md` for the consumer-facing API.

**The erasure is load-bearing.** `HarmonyScreen` wraps `any HarmonyDestination`; identity (`==`/`hash`/`id`) comes from `AnyHashable(destination)`, so two destinations of different types are never equal. `HarmonyCoordinator`, `HarmonyStack`, `HarmonySplit*`, and `@HarmonyCoordinated` are all **non-generic**; only `HarmonyTabCoordinator<Tab>` / `HarmonyTabs<Tab>` stay generic (over the tab enum). `HarmonyStack` registers one `navigationDestination(for: HarmonyScreen.self)`, and `HarmonyScreen.body` opens the existential to render the real view — the only `AnyView` is at each screen's root. Public navigation methods take `any HarmonyDestination` (so call sites qualify the case name, e.g. `push(Screen.detail)` — leading-dot can't infer the type).

## Build & test

```bash
# macOS (fast; runs from the package root)
swift test

# iOS simulator (Swift Testing; some tests are iOS-gated)
xcodebuild test -scheme HarmonyFlow -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# the example app (its Xcode project lives at HarmonyTestHarness/)
cd HarmonyTestHarness
xcodebuild -scheme HarmonyTestHarness -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Always verify on both platforms** before declaring a navigation change done — behavior legitimately differs (see Platform differences). Run the harness build too when you touch view code; tests don't catch every SwiftUI misuse.

The package depends on `ios-tooling/Suite` and `ios-tooling/chronicle` (resolved from GitHub). `Tab.allCases`, `@Observable`, and Swift Testing are used heavily.

## Repository layout

```
Sources/HarmonyFlow/
  HarmonyDestination.swift            protocol each feature conforms its own screen type to
  HarmonyScreen.swift                 the erased box (struct) wrapping any HarmonyDestination
  HarmonyScreenConfiguration.swift    passed to every body(configuration:); holds .coordinator
  HarmonyCoordinated.swift            @HarmonyCoordinated property wrapper (reads coordinator from environment)
  HarmonyAction.swift                 push / bottomSheet / partialModal / fullScreenModal (+ iOS detent defaults)
  HarmonyDetent.swift                 platform-neutral detent; maps to PresentationDetent (iOS) + height resolver (both)
  HarmonyNavigationConfiguration.swift per-presentation options (action, detents, interactive dismiss)
  HarmonyStack.swift                  renders a single HarmonyCoordinator (NavigationStack + sheet/cover + bottom-sheet overlay)
  HarmonyBottomSheet.swift            the draggable overlay card (HarmonyFlow-rendered, NOT a system sheet)
  HarmonyBottomSheetHosting.swift     internal protocol; lets a tab coordinator host a stack's bottom sheet
  HarmonyCoordinator/                 the stack coordinator, split across +Show / +Path / +Present / +Reading / +Persistence
  HarmonyTabs/                        HarmonyTab, HarmonyTabCoordinator (+Persistence), HarmonyTabs view
  HarmonySplit/                       HarmonySplitCoordinator (+Persistence), HarmonySplit view
  Persistence/                        HarmonyScreenRegistry + HarmonyScreen Codable (polymorphic encode/decode)
Tests/HarmonyFlowTests/               Swift Testing suites (incl. rendering smoke tests)
HarmonyTestHarness/                   example app (Xcode project, synchronized folder groups)
```

Conventions (from the owner's global `CLAUDE.md`, enforced here): files ≈100 lines or less — split large types by functionality into `Type+Feature.swift`; no multi-line function declarations; full-screen views named `…Screen`; no UIKit fallbacks in app code; no hard-coded layout dimensions; `async/await` only (no Combine/GCD). Commit messages must not mention LLM assistance. **Never push** unless explicitly asked.

## Load-bearing invariants — do not break these

1. **`removeFromParentCoordinator()` is the single teardown funnel.** Every dismissal path (`dismiss`, `dismissStack`, swipe, replacement, `collapse`) ends here. Two things hang off it: clearing the correct parent slot *by identity*, and resolving a pending present-for-result continuation (via the slot `didSet`s — see #4). If you add a new way to remove a coordinator, route it through here or you'll leak suspended tasks / orphan continuations.

2. **Two child slots, not one.** A coordinator has `modalCoordinator` (partial + full-screen) **and** `bottomSheetCoordinator`. They're separate so a bottom sheet can persist while a modal is presented over it. `sheetCoordinator` / `fullScreenCoordinator` are *computed accessors over `modalCoordinator`* used as SwiftUI presentation bindings — their setters must only clear when written `nil` and only for their own action kind (SwiftUI writes nil through inactive bindings during updates).

3. **Bottom sheets bubble to a host and never stack.** `bottomSheetHost` walks up: a bottom sheet presented from inside a bottom sheet replaces it. Under tabs, `externalBottomSheetHost` redirects a stack's bottom sheet to the `HarmonyTabCoordinator` so it renders above the tab bar. Routing lives in `HarmonyCoordinator.addChild`.

4. **Present-for-result resolves in slot `didSet`.** `modalCoordinator` / `bottomSheetCoordinator` (and the tab coordinator's slot) call `tearDownPresentation()` on the *old* value when reassigned. That **recursively** resolves the removed coordinator's continuation *and* its descendants' (by nil-ing its own slots, which re-enter the same path), so dismissing a parent flow never orphans a nested present-for-result. `resolvePendingPresentation()` is idempotent, so the cascade is crash-safe. Don't move continuation resumption into individual dismiss methods — it'll double-resume or miss paths.

5. **`HarmonyStack` holds its coordinator as a `let`, not `@State`.** Container views (split columns, `showDetail`) swap coordinators out; `@State` would pin the first instance forever. The body uses `@Bindable var coordinator = coordinator` to get presentation bindings.

6. **Coordinators are root-level containers.** `HarmonyTabs` / `HarmonySplit` can't be presented *inside* a `HarmonyStack` (everything there is inside a `NavigationStack`). They're app roots only.

7. **Reads go through the `presented…` accessors, not the raw slots.** The public read API (`root`, `path`, `presentedModal`, `presentedBottomSheet`, `topCoordinator`, `screens`, `topScreen` in `HarmonyCoordinator+Reading.swift`; `presentedBottomSheet`, `topCoordinator`, `topScreen` on `HarmonyTabCoordinator`) is what apps, tests and agent control surfaces use instead of decoding `encodedState()`. The slots stay internal. `presentedBottomSheet` resolves the tab hoist: under tabs a stack's own `bottomSheetCoordinator` slot is always nil and its sheet sits on the tab coordinator with `parentCoordinator` pointing back (the same "belongs to us" test `collapse()` uses), so anything that walks the tree to read it must use the accessor. On-screen order is own stack, bottom sheet, modal; `screens` and `topCoordinator` both encode that, so change them together. `dismissTopFlow()` goes through `dismissStack()`, i.e. the funnel in #1.

## Platform differences (expected, not bugs)

- **macOS has no `fullScreenCover`** → `fullScreenModal` degrades to a system sheet. `HarmonyAction.isSheet` returns `true` for `fullScreenModal` on macOS, and `fullScreenCoordinator` returns `nil` there. Tests that assert iOS routing are `#if os(iOS)`-gated; the macOS branch asserts the sheet path.
- **`PresentationDetent` is iOS-only.** `HarmonyDetent`'s `presentationDetent` mapping and the action detent defaults are `#if os(iOS)`. The bottom-sheet overlay uses `resolvedHeight(in:)` instead, which works on both.
- **Tab-bar hiding** (`.toolbarVisibility(.hidden, for: .tabBar)`) is iOS-only.

## Presentations across tabs (measured on the simulator; don't re-derive)

SwiftUI draws sheets and covers over the whole window, so one tab's presentation interacts with the others. Measured in the harness on iOS 26.5 and 27.1, with the coordinator's state logged beside screenshots:

- **Selecting another tab in code leaves the earlier tab's sheet on screen**, over the newly selected tab; left to SwiftUI, a push in another tab does the same. The coordinator keeps the sheet in the earlier tab, so the selected tab's top screen is not always what is frontmost. `HarmonyTabCoordinator.topCoordinator` / `topScreen` exist for exactly this: a tab presenting a modal comes before the selected tab.
- **`HarmonyTabCoordinator.show` closes that sheet for a push or a bottom sheet.** It calls `dismissModals()` on every other tab's stack first, because nothing else would. Checked on screen, including a `show` arriving 0.3 s after the sheet started animating in: the sheet goes and UIKit logs nothing. Plain `selectedTab = …` is deliberately left alone.
- **Showing a modal in another tab already replaces the earlier tab's sheet.** SwiftUI dismisses it, writes nil through its binding (the `sheetCoordinator` setter tears it down, so a pending `present` resumes with nil), then presents the new modal. `HarmonyTabCoordinator.show` must not dismiss the other tab's modal itself when the destination is a modal: that was tried, gave identical screens, and made UIKit log "Attempt to dismiss from view controller … while a presentation or dismiss is in progress!".
- **A modal requested while another tab's sheet is still animating in is dropped.** UIKit refuses it ("Attempt to present … which is already presenting …") and nothing retries, so the coordinator lists a flow that is not on screen until the next change. A gap of 0.4 s fails and 0.8 s works. Not fixed; pacing presentations in `HarmonyStack` would be the place.

Unit tests cannot see any of this, because they run without SwiftUI's presentation machinery. To measure again, drive `HarmonyTestHarness` from a temporary `.task` in `ContentView` keyed on a launch argument, `NSLog` each tab's `screens` and `tabs.topScreen`, capture the console with `xcrun simctl spawn <udid> log stream`, and screenshot with `xcrun simctl io <udid> screenshot`. Revert the driver afterwards.

## Persistence pattern

`HarmonyScreen` is unconditionally `Codable` (it was, when generic, gated on `Screen: Codable`; erasure removed the conditional). Because the box holds `any HarmonyDestination`, decode can't recover the concrete type alone — so `HarmonyScreenRegistry` maps a stable string key ⇄ a Codable destination type. Consumers call `HarmonyScreenRegistry.register(_:forKey:)` once per type (each framework registers its own; the registry is a lock-guarded `nonisolated(unsafe)` store so it's reachable from `HarmonyScreen`'s nonisolated Codable methods). `HarmonyScreen` encodes as `{ type: key, value: payload }`; an **unregistered** type throws on encode/decode, which restore paths treat as "skip".

Each coordinator level has a sibling `+Persistence.swift` with a `Snapshot` struct (now non-generic — `HarmonyTabSnapshot<Tab>` stays generic over the tab enum). Recursion through the tree is broken with `[Snapshot]` (0-or-1 element) fields, since structs can't recurse directly. Restoration must **rebuild `parentCoordinator` / `externalBottomSheetHost` links**, not just the tree shape — otherwise restored children can't dismiss. Snapshot-missing tabs deliberately keep the fresh stacks the designated init created (forward-compat with added tab cases).

## Gotchas

- Navigation methods take `any HarmonyDestination`, so **leading-dot shorthand doesn't work** — qualify the case (`push(Screen.detail)`, not `push(.detail)`). In tests, free `==` overloads (`HarmonyScreen` vs the test enum) keep assertions like `root == .detail` reading naturally; arguments to methods still need qualifying.
- Container coordinators should be fetched from the environment **optionally** in screens shared across container types (a split root has no tab coordinator, and vice-versa). The stack `HarmonyCoordinator` is always present.
- `finish(returning:)` takes `(any Sendable)?` — that's the Swift 6 continuation-crossing requirement, not a design choice.
- `HarmonyStackReadingTests` and `HarmonyTabReadingTests` import HarmonyFlow **without `@testable`** on purpose: they only compile while the read API is public. Keep internal names (`modalCoordinator`, `sheetCoordinator`, …) out of those two files.