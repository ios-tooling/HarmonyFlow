//
//  ContentView.swift
//  HarmonyTestHarness
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI
import Harmony

struct ContentView: View {
	@State private var coordinator = HarmonyTabCoordinator(selected: AppTab.home)

	var body: some View {
		HarmonyTabs(coordinator)
	}
}

#Preview {
	ContentView()
}
