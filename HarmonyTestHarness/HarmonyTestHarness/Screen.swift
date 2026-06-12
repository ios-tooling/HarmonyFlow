//
//  Screen.swift
//  HarmonyTestHarness
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI
import Harmony

enum Screen: HarmonyScreen {
	case main, settings, titled(String)
	
	var id: String {
		switch self {
		case .main: "main"
		case .settings: "settings"
		case .titled(let title): "titled.\(title)"
		}
	}
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	func body(configuration: HarmonyCoordinator<Self>.ScreenConfiguration) -> some View {
		switch self {
		case .main:
			VStack {
				Text("main")

				Button("Settings") {
					configuration.coordinator.partialModal(.settings)
				}

				Button("Push Settings") {
					configuration.coordinator.push(.settings)
				}

				Button("Full Screen Settings") {
					configuration.coordinator.fullScreenModal(.settings)
				}

				Button("Bottom Sheet") {
					configuration.coordinator.show(.settings, config: .init(action: .bottomSheet, detents: [.fraction(0.25), .medium, .fraction(0.85)]))
				}

				Button("Tall Sheet") {
					configuration.coordinator.show(.settings, config: .init(action: .partialModal, detents: [.fraction(0.75), .large], isInteractiveDismissDisabled: true))
				}

				Button("Push Titled") {
					configuration.coordinator.push(.titled("Titled"))
				}

				CloseFlowButton()

				SettingsTabButton()

				ToggleTabBarButton()

				PresentResultButton()
			}
			.navigationTitle("Main")

		case .settings:
			VStack {
				Text("settings")

				Button("Dismiss") {
					configuration.coordinator.dismiss()
				}
				Button("Finish with 🎁") {
					configuration.coordinator.finish(returning: "🎁")
				}
				Button("main") {
					configuration.coordinator.push(.main)
				}

			}
			.navigationTitle("Settings")
			
		case .titled(let title):
			VStack {
				Text(title)

				Button("Dismiss") {
					configuration.coordinator.dismiss()
				}
				Button("Push + 1") {
					configuration.coordinator.push(.titled("\(title) + 1"))
				}
				Button("main") {
					configuration.coordinator.pop(to: .main)
				}

			}
			.navigationTitle(title)
		}
		
	}
}
