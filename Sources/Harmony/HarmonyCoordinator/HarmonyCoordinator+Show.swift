//
//  HarmonyCoordinator+Show.swift
//  Harmony
//
//  Created by Ben Gottlieb on 6/9/26.
//

import Foundation

extension HarmonyCoordinator {
	public func show(_ screen: Screen, config: HarmonyNavigationConfiguration) {
		let action = config.action
		
		switch action {
		case .push:
			_screens.append(.init(screen: screen, action: action))

		case .bottomSheet, .partialModal, .fullScreenModal:
			addChild(screen, configuration: config)
		}
	}
	
	public func push(_ screen: Screen) { show(screen, config: .init(action: .push)) }
	public func bottomSheet(_ screen: Screen) { show(screen, config: .init(action: .bottomSheet)) }
	public func partialModal(_ screen: Screen) { show(screen, config: .init(action: .partialModal)) }
	public func fullScreenModal(_ screen: Screen) { show(screen, config: .init(action: .fullScreenModal)) }

	public func dismiss() {
		if _screens.isEmpty {
			removeFromParentCoordinator()
		} else {
			_screens.removeLast()
		}
	}

	public func dismissStack() {
		removeFromParentCoordinator()
	}

	public func popToRoot() {
		_screens.removeAll()
	}

	// returns the stack to its pristine root: pops all pushes and drops anything it presented
	public func collapse() {
		_screens.removeAll()
		modalCoordinator = nil
		bottomSheetCoordinator = nil
	}
}
