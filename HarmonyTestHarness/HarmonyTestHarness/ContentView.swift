//
//  ContentView.swift
//  HarmonyTestHarness
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI
import Harmony

struct ContentView: View {
	@State private var coordinator = HarmonyCoordinator([Screen.main])
	
	var body: some View {
		HarmonyStack(coordinator)
//		{
//			Button(action: { coordinator.push(.main) }) {
//				Text("Go to Main")
//			}
//		}
	}
}

#Preview {
	ContentView()
}
