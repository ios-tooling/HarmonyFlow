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
			var path = self.fullPath
			if self.suppliesRoot, !path.isEmpty { path.remove(at: 0) }
			return NavigationPath(path)
		}, set: { newPath in
			var navPath = self.fullPath
			if self.suppliesRoot { navPath.remove(at: 0) }
			
			while newPath.count < navPath.count {
				navPath.removeLast()
				self._screens.removeLast()
			}
		})
	}
}
