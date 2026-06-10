//
//  Screen.swift
//  HarmonyTestHarness
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI
import Harmony

enum Screen: String, HarmonyScreen {
	case main, settings
	
	var id: String { rawValue }
	func hash(into hasher: inout Hasher) {
		hasher.combine(rawValue)
	}
	
	func body(configuration: HarmonyCoordinator<Self>.ScreenConfiguration) -> some View {
		switch self {
		case .main:
			VStack {
				Text("main")
				
				Button("Settings") {
					configuration.coordinator.push(.settings)
				}
			}
			
		case .settings:
			VStack {
				Button("Dismiss") {
					configuration.coordinator.dismiss()
				}

				Text("settings")
			}
		}
	}
}
