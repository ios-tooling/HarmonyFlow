//
//  HarmonyCoordinator.swift
//  Harmony
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI

@MainActor @Observable public class HarmonyCoordinator<Screen: HarmonyScreen>: Identifiable {
	var _screens: [ScreenAction] = []
	
	var parentCoordinator: HarmonyCoordinator<Screen>?
	var modalCoordinator: HarmonyCoordinator<Screen>?
	var bottomSheetCoordinator: HarmonyCoordinator<Screen>?
	var root: Screen
	var configuration = HarmonyNavigationConfiguration(action: .push)

	var action: HarmonyAction { configuration.action }
	
	nonisolated public var id: ObjectIdentifier { ObjectIdentifier(self) }
	
	public init(_ screen: Screen) {
		root = screen
	}
	
	public init(_ path: [Screen]) {
		precondition(!path.isEmpty, "HarmonyCoordinator requires at least one screen")
		root = path[0]
		_screens = path.dropFirst().map { ScreenAction(screen: $0, action: .push) }
	}
	
	func removeFromParentCoordinator() {
		guard let parentCoordinator else { return }

		if parentCoordinator.modalCoordinator === self { parentCoordinator.modalCoordinator = nil }
		if parentCoordinator.bottomSheetCoordinator === self { parentCoordinator.bottomSheetCoordinator = nil }
	}

	func addChild(_ screen: Screen, configuration: HarmonyNavigationConfiguration) {
		let new = HarmonyCoordinator([screen])
		new.configuration = configuration
		new.parentCoordinator = self

		if configuration.action == .bottomSheet {
			bottomSheetCoordinator = new
		} else {
			modalCoordinator = new
		}
	}

	var sheetCoordinator: HarmonyCoordinator<Screen>? {
		get {
			guard let modalCoordinator, modalCoordinator.action.isSheet else { return nil }
			return modalCoordinator
		}
		set {
			if newValue == nil, modalCoordinator?.action.isSheet == true { modalCoordinator = nil }
		}
	}

	var fullScreenCoordinator: HarmonyCoordinator<Screen>? {
		get {
			#if os(macOS)
				return nil
			#else
				guard let modalCoordinator, modalCoordinator.action == .fullScreenModal else { return nil }
				return modalCoordinator
			#endif
		}
		set {
			if newValue == nil, modalCoordinator?.action == .fullScreenModal { modalCoordinator = nil }
		}
	}
}
