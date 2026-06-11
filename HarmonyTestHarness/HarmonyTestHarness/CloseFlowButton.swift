//
//  CloseFlowButton.swift
//  HarmonyTestHarness
//
//  Created by Ben Gottlieb on 6/10/26.
//

import SwiftUI
import Harmony

struct CloseFlowButton: View {
	@Environment(HarmonyCoordinator<Screen>.self) private var coordinator

	var body: some View {
		Button("Close Flow") {
			coordinator.dismissStack()
		}
	}
}
