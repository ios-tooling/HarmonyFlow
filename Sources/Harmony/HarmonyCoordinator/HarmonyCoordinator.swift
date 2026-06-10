//
//  HarmonyCoordinator.swift
//  Harmony
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI

@MainActor @Observable public class HarmonyCoordinator<Screen: HarmonyScreen> {
	var _screens: [ScreenAction] = []
	
	var parentCoordinator: HarmonyCoordinator<Screen>?
	var suppliesRoot = false
	
	public init(parentCoordinator: HarmonyCoordinator<Screen>? = nil) {
		self.parentCoordinator = parentCoordinator
	}

	public init(_ kind: Screen.Type) {
	}

	public init(_ path: [Screen]) {
		_screens = path.map { ScreenAction(screen: $0, action: .push) }
	}

	var allScreens: [Screen] {
		get {
			if let parentCoordinator { return parentCoordinator.allScreens + fullPath }
			return fullPath
		}
	}
}
