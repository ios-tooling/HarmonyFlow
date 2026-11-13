//
//  HarmonyTabCoordinator.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI

@MainActor @Observable public class HarmonyTabCoordinator<Tab: HarmonyTab>: HarmonyBottomSheetHosting {
	public var selectedTab: Tab
	public var isTabBarHidden = false
	var bottomSheetCoordinator: HarmonyCoordinator? {
		didSet { if oldValue !== bottomSheetCoordinator { oldValue?.tearDownPresentation() } }
	}
	var stacks: [Tab: HarmonyCoordinator] = [:]

	public init(selected: Tab) {
		selectedTab = selected
		for tab in Tab.allCases {
			let stack = HarmonyCoordinator(tab.rootScreen)
			stack.externalBottomSheetHost = self
			stacks[tab] = stack
		}
	}

	public func coordinator(for tab: Tab) -> HarmonyCoordinator {
		guard let stack = stacks[tab] else {
			preconditionFailure("HarmonyTabCoordinator has no stack for \(tab)")
		}
		return stack
	}

	/// The bottom sheet showing above the tab bar, if any, whichever tab presented it.
	public var presentedBottomSheet: HarmonyCoordinator? { bottomSheetCoordinator }

	/// The coordinator of the frontmost flow on screen.
	///
	/// A modal covers the whole window whichever tab presented it, and stays up when another tab is selected in
	/// code, so a tab presenting a modal comes first (the selected tab, if it is presenting one); then the bottom
	/// sheet above the tab bar; otherwise the selected tab's own stack.
	public var topCoordinator: HarmonyCoordinator {
		let selected = coordinator(for: selectedTab)
		let modal = selected.presentedModal ?? Tab.allCases.lazy.compactMap { self.coordinator(for: $0).presentedModal }.first
		return modal?.topCoordinator ?? bottomSheetCoordinator?.topCoordinator ?? selected
	}

	/// The frontmost screen on screen: the top screen of `topCoordinator`.
	public var topScreen: HarmonyScreen { topCoordinator.topScreen }

	/// Selects `tab`, then shows the destination on its stack.
	///
	/// A push or a bottom sheet first closes any modal another tab is presenting, which would otherwise stay on
	/// screen over this tab (a `present` caller waiting on it resumes with `nil`). When the destination is itself
	/// a modal nothing is closed here: SwiftUI replaces the other tab's modal as it presents the new one.
	public func show(_ destination: any HarmonyDestination, in tab: Tab, config: HarmonyNavigationConfiguration = .init(action: .push)) {
		selectedTab = tab
		if config.action == .push || config.action == .bottomSheet {
			for (other, stack) in stacks where other != tab { stack.dismissModals() }
		}
		coordinator(for: tab).show(destination, config: config)
	}

	public func collapse(_ tab: Tab? = nil) {
		coordinator(for: tab ?? selectedTab).collapse()
	}

	/// Dismisses only the frontmost flow presented in `tab` (the selected tab by default). Unlike `collapse(_:)`,
	/// the tab's pushed screens and any flows beneath the top one stay. Returns `false` when nothing is presented.
	@discardableResult public func dismissTopFlow(in tab: Tab? = nil) -> Bool {
		coordinator(for: tab ?? selectedTab).dismissTopFlow()
	}
}
