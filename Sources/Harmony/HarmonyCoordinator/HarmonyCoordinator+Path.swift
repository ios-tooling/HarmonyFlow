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
	
	var navigationPathBinding: Binding<NavigationPath> {
		Binding(get: {
			return NavigationPath(self.fullPath)
		}, set: { newPath in
			var navPath = self.fullPath
			while newPath.count < navPath.count {
				navPath.removeLast()
				self._screens.removeLast()
			}
		})
	}
}
