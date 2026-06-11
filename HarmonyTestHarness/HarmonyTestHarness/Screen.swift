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
					configuration.coordinator.partialModal(.settings)
				}

				CloseFlowButton()
			}
			.navigationTitle("Main")

		case .settings:
			VStack {
				Text("settings")

				Button("Dismiss") {
					configuration.coordinator.dismiss()
				}
				Button("main") {
					configuration.coordinator.push(.main)
				}

			}
			.navigationTitle("Settings")
		}
	}
}
