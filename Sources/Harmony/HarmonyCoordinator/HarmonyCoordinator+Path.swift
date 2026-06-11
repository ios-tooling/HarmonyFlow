//
//  HarmonyCoordinator+Path.swift
//  Harmony
//
//  Created by Ben Gottlieb on 6/10/26.
//

import SwiftUI

extension HarmonyCoordinator {
	var fullPath: [Screen] {
		_screens.map(\.screen)
	}
	
	var pathBinding: Binding<[Screen]> {
		Binding(get: {
			self.fullPath
		}, set: { newPath in
			self._screens = newPath.map { ScreenAction(screen: $0, action: .push) }
		})
	}
}
