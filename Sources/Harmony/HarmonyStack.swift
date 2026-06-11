//
//  HarmonyStack.swift
//  Harmony
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI


public struct HarmonyStack<Screen: HarmonyScreen>: View {
	@State private var coordinator: HarmonyCoordinator<Screen>

	public init(_ coordinator: HarmonyCoordinator<Screen>) {
		self.coordinator = coordinator
	}
	
//	init(_ screen: Screen.Type, coordinator: HarmonyCoordinator<Screen>?) {
//		_coordinator = State(initialValue: coordinator ?? HarmonyCoordinator<Screen>())
//	}
	
	var config: HarmonyCoordinator<Screen>.ScreenConfiguration { .init(coordinator: coordinator) }
	
	public var body: some View {
		NavigationStack(path: coordinator.pathBinding) {
			coordinator.root.body(configuration: config)
				.navigationDestination(for: Screen.self) { screen in
					screen.body(configuration: config)
				}
		}
		.environment(coordinator)
		#if os(iOS)
			.sheet(item: $coordinator.sheetCoordinator) { sheet in
				HarmonyStack(sheet)
					.presentationDetents(sheet.presentationDetents)
					.interactiveDismissDisabled(sheet.configuration.isInteractiveDismissDisabled)
			}
			.fullScreenCover(item: $coordinator.fullScreenCoordinator) { cover in
				HarmonyStack(cover)
			}
		#else
			.sheet(item: $coordinator.sheetCoordinator) { sheet in
				HarmonyStack(sheet)
					.interactiveDismissDisabled(sheet.configuration.isInteractiveDismissDisabled)
			}
		#endif
	}
}

//extension HarmonyStack where Root == EmptyView {
//	public init(_ coordinator: HarmonyCoordinator<Screen>) {
//		coordinator.suppliesRoot = true
//		self.init(Screen.self, coordinator: coordinator, root: { EmptyView() })
//	}
//	
//	public init(screen: Screen, coordinator: HarmonyCoordinator<Screen>? = nil) {
//		let coordinator = coordinator ?? HarmonyCoordinator<Screen>()
//		coordinator.suppliesRoot = true
//		self.root = EmptyView()
//		coordinator.show(screen, config: .init(action: .push))
//		_coordinator = State(initialValue: coordinator)
//	}
//}
