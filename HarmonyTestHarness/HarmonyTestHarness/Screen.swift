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

				Button("Bottom Sheet") {
					configuration.coordinator.show(.settings, config: .init(action: .bottomSheet, detents: [.fraction(0.25), .medium, .fraction(0.85)]))
				}

				Button("Tall Sheet") {
					configuration.coordinator.show(.settings, config: .init(action: .partialModal, detents: [.fraction(0.75), .large], isInteractiveDismissDisabled: true))
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
