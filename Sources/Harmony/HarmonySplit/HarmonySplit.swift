//
//  HarmonySplit.swift
//  Harmony
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI

public struct HarmonySplit<Screen: HarmonyScreen>: View {
	let coordinator: HarmonySplitCoordinator<Screen>

	public init(_ coordinator: HarmonySplitCoordinator<Screen>) {
		self.coordinator = coordinator
	}

	public var body: some View {
		@Bindable var coordinator = coordinator

		Group {
			if let content = coordinator.contentCoordinator {
				NavigationSplitView(columnVisibility: $coordinator.columnVisibility) {
					HarmonyStack(coordinator.sidebarCoordinator)
				} content: {
					HarmonyStack(content)
				} detail: {
					HarmonyStack(coordinator.detailCoordinator)
				}
			} else {
				NavigationSplitView(columnVisibility: $coordinator.columnVisibility) {
					HarmonyStack(coordinator.sidebarCoordinator)
				} detail: {
					HarmonyStack(coordinator.detailCoordinator)
				}
			}
		}
		.environment(coordinator)
	}
}
