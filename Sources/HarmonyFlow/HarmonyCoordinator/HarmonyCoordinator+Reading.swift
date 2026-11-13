//
//  HarmonyCoordinator+Reading.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 11/12/26.
//

import Foundation

// these read the coordinator's observed state, so SwiftUI views and
// withObservationTracking that read them update when the stack changes
extension HarmonyCoordinator {
	/// The modal flow (sheet or full-screen cover) presented from this coordinator, if any.
	public var presentedModal: HarmonyCoordinator? { modalCoordinator }

	/// The bottom sheet presented from this coordinator, if any.
	///
	/// Under `HarmonyTabs` a tab's bottom sheet is hosted by the tab coordinator, so it draws above the tab
	/// bar; it is still reported here, by the coordinator that presented it.
	public var presentedBottomSheet: HarmonyCoordinator? {
		if let bottomSheetCoordinator { return bottomSheetCoordinator }
		guard let hosted = externalBottomSheetHost?.bottomSheetCoordinator, hosted.parentCoordinator === self else { return nil }
		return hosted
	}

	/// The coordinator of the frontmost flow: follows what is presented, a modal above a bottom sheet, until
	/// it reaches a flow that presents nothing. This coordinator itself when it presents nothing.
	public var topCoordinator: HarmonyCoordinator {
		(presentedModal ?? presentedBottomSheet)?.topCoordinator ?? self
	}

	/// Every screen showing from this coordinator's root up: the root, the pushed `path`, then the screens of
	/// the bottom sheet and of the modal presented from here (the modal sits on top), each read the same way.
	public var screens: [HarmonyScreen] {
		[root] + path + (presentedBottomSheet?.screens ?? []) + (presentedModal?.screens ?? [])
	}

	/// The frontmost screen: the last of `screens`.
	public var topScreen: HarmonyScreen {
		let top = topCoordinator
		return top.path.last ?? top.root
	}
}
