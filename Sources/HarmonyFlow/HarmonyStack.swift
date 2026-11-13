//
//  HarmonyStack.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI

public struct HarmonyStack: View {
	// not @State: the coordinator is owned by its parent (app, tab, split, or
	// presenting coordinator), and container views may swap it out
	let coordinator: HarmonyCoordinator

	public init(_ coordinator: HarmonyCoordinator) {
		self.coordinator = coordinator
	}

	var config: HarmonyScreenConfiguration { .init(coordinator: coordinator) }

	public var body: some View {
		@Bindable var coordinator = coordinator

		NavigationStack(path: coordinator.pathBinding) {
			coordinator.root.body(configuration: config)
				.navigationDestination(for: HarmonyScreen.self) { screen in
					screen.body(configuration: config)
				}
		}
		.environment(coordinator)
		.overlay(alignment: .bottom) {
			if let bottomSheet = coordinator.bottomSheetCoordinator {
				HarmonyBottomSheet(coordinator: bottomSheet)
					.id(bottomSheet.id)
					.transition(.identity)		// the sheet's layers transition individually: card slides, scrim fades
			}
		}
		.animation(.spring, value: coordinator.bottomSheetCoordinator?.id)
		#if os(iOS)
			.sheet(item: $coordinator.shownSheetCoordinator) { sheet in
				HarmonyStack(sheet)
					.onAppear { HarmonyPresentationPacer.shared.notePresentation() }
					.presentationDetents(sheet.presentationDetents)
					.interactiveDismissDisabled(sheet.configuration.isInteractiveDismissDisabled)
			}
			.fullScreenCover(item: $coordinator.shownFullScreenCoordinator) { cover in
				HarmonyStack(cover)
					.onAppear { HarmonyPresentationPacer.shared.notePresentation() }
			}
		#else
			.sheet(item: $coordinator.shownSheetCoordinator) { sheet in
				HarmonyStack(sheet)
					.onAppear { HarmonyPresentationPacer.shared.notePresentation() }
					.interactiveDismissDisabled(sheet.configuration.isInteractiveDismissDisabled)
			}
		#endif
	}
}
