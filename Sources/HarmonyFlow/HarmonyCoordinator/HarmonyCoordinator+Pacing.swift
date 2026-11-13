//
//  HarmonyCoordinator+Pacing.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 11/13/26.
//

import Foundation

extension HarmonyCoordinator {
	// what HarmonyStack binds its sheet and cover to: sheetCoordinator / fullScreenCoordinator, minus a modal that
	// is still waiting its turn. A held modal is not the one on screen, so SwiftUI's nil writes (for the modal it
	// is taking down, or through the inactive binding) must not clear it
	var shownSheetCoordinator: HarmonyCoordinator? {
		get { sheetCoordinator.flatMap { $0.isHeld ? nil : $0 } }
		set { if newValue == nil, modalCoordinator?.isHeld == false { sheetCoordinator = nil } }
	}

	var shownFullScreenCoordinator: HarmonyCoordinator? {
		get { fullScreenCoordinator.flatMap { $0.isHeld ? nil : $0 } }
		set { if newValue == nil, modalCoordinator?.isHeld == false { fullScreenCoordinator = nil } }
	}
}
