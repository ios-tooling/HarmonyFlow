//
//  HarmonyCoordinator+Path.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/10/26.
//

import SwiftUI

extension HarmonyCoordinator {
	/// The screens pushed above `root`, bottom to top; does not include `root`.
	public var path: [HarmonyScreen] {
		_screens.map(\.screen)
	}

	var pathBinding: Binding<[HarmonyScreen]> {
		Binding(get: {
			self.path
		}, set: { newPath in
			self._screens = newPath.map { ScreenAction(screen: $0, action: .push) }
		})
	}
}
