//
//  ToggleTabBarButton.swift
//  HarmonyTestHarness
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI
import Harmony

struct ToggleTabBarButton: View {
	@Environment(HarmonyTabCoordinator<AppTab>.self) private var tabs: HarmonyTabCoordinator<AppTab>?

	var body: some View {
		if let tabs {
			Button(tabs.isTabBarHidden ? "Show Tab Bar" : "Hide Tab Bar") {
				tabs.isTabBarHidden.toggle()
			}
		}
	}
}
