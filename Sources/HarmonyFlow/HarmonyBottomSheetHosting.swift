//
//  HarmonyFlowBottomSheetHosting.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/11/26.
//

import Foundation

@MainActor protocol HarmonyBottomSheetHosting<Screen>: AnyObject {
	associatedtype Screen: HarmonyScreen

	var bottomSheetCoordinator: HarmonyCoordinator<Screen>? { get set }
}
