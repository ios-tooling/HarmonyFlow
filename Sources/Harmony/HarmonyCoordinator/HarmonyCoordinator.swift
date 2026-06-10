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
	var childCoordinator: HarmonyCoordinator<Screen>?
	var root: Screen
	var action = HarmonyAction.push
	
	nonisolated public var id: String { "\(self)" }
	
	public init(_ screen: Screen) {
		root = screen
	}
	
	public init(_ path: [Screen]) {
		root = path[0]
		_screens = path.dropFirst().map { ScreenAction(screen: $0, action: .push) }
	}
	
	func removeFromParentCoordinator() {
		guard let parentCoordinator else { return }
		
		parentCoordinator.childCoordinator = nil
	}
	
	func addChild(_ screen: Screen, action: HarmonyAction) {
		let new = HarmonyCoordinator([screen])
		new.action = action
		
		childCoordinator = new
		new.parentCoordinator = self
		
	}
	
	var sheetCoordinator: HarmonyCoordinator<Screen>? {
		get {
			guard let childCoordinator, childCoordinator.action.isSheet else { return nil }
			return childCoordinator
		}
		set {
			childCoordinator = nil
		}
	}
	
	var fullScreenCoordinator: HarmonyCoordinator<Screen>? {
		get {
			guard let childCoordinator, childCoordinator.action == .fullScreenModal else { return nil }
			return childCoordinator
		}
		set {
			childCoordinator = nil
		}
	}
}
