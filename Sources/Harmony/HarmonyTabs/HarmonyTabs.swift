//
//  HarmonyTabs.swift
//  Harmony
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI

public struct HarmonyTabs<Tab: HarmonyTab>: View {
	@State private var coordinator: HarmonyTabCoordinator<Tab>

	public init(_ coordinator: HarmonyTabCoordinator<Tab>) {
		_coordinator = State(initialValue: coordinator)
	}

	public var body: some View {
		@Bindable var coordinator = coordinator

		TabView(selection: $coordinator.selectedTab) {
			ForEach(Array(Tab.allCases), id: \.self) { tab in
				SwiftUI.Tab(value: tab) {
					HarmonyStack(coordinator.coordinator(for: tab))
				} label: {
					tab.label
				}
			}
		}
		.overlay(alignment: .bottom) {
			if let bottomSheet = coordinator.bottomSheetCoordinator {
				HarmonyBottomSheet(coordinator: bottomSheet)
					.id(bottomSheet.id)
					.transition(.identity)
			}
		}
		.animation(.spring, value: coordinator.bottomSheetCoordinator?.id)
		.environment(coordinator)
	}
}
