//
//  AppTab.swift
//  HarmonyTestHarness
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI
import Harmony

enum AppTab: String, HarmonyTab {
	case home, settings

	var rootScreen: Screen {
		switch self {
		case .home: .main
		case .settings: .settings
		}
	}

	var label: some View {
		switch self {
		case .home: Label("Home", systemImage: "house")
		case .settings: Label("Settings", systemImage: "gear")
		}
	}
}
