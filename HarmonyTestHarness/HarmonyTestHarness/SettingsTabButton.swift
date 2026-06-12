//
//  SettingsTabButton.swift
//  HarmonyTestHarness
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI
import Harmony

struct SettingsTabButton: View {
	@Environment(HarmonyTabCoordinator<AppTab>.self) private var tabs

	var body: some View {
		Button("Titled Tab → main") {
			tabs.show(.titled("Subtitled"), in: .settings)
		}
	}
}
