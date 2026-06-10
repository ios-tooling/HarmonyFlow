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
		
		_screens.append(.init(screen: screen, action: action))
	}
	
	public func push(_ screen: Screen) { show(screen, config: .init(action: .push)) }
	public func modal(_ screen: Screen) { show(screen, config: .init(action: .modal)) }
	
	public func dismiss() {
		_screens.removeLast()
	}
}
