//
//  HarmonyStack.swift
//  Harmony
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI


public struct HarmonyStack<Screen: HarmonyScreen, Root: View>: View {
	@State private var coordinator: HarmonyCoordinator<Screen>
	let root: Root

	public init(_ type: Screen.Type, root: () -> Root) {
		self.init(type, coordinator: nil, root: root)
	}
	
	public init(_ coordinator: HarmonyCoordinator<Screen>, root: () -> Root) {
		self.init(Screen.self, coordinator: coordinator, root: root)
	}
	
	init(_ type: Screen.Type, coordinator: HarmonyCoordinator<Screen>?, root: () -> Root) {
		self.root = root()
		_coordinator = State(initialValue: coordinator ?? HarmonyCoordinator<Screen>())
		if root is EmptyView { _coordinator.wrappedValue.suppliesRoot = true }
	}
	
	var config: HarmonyCoordinator<Screen>.ScreenConfiguration { .init(coordinator: coordinator) }
	
	public var body: some View {
		NavigationStack(path: coordinator.navigationPathBinding) {
			VStack {
				if root is EmptyView {
					if let rootScreen = coordinator.allScreens.first {
						rootScreen.body(configuration: config)
					} else {
						Text("MISSING VIEW")
					}
				} else {
					root
				}
			}
			.navigationDestination(for: Screen.self) { screen in
				screen.body(configuration: config)
			}
		}
	}
}

extension HarmonyStack where Root == EmptyView {
	public init(_ coordinator: HarmonyCoordinator<Screen>) {
		coordinator.suppliesRoot = true
		self.init(Screen.self, coordinator: coordinator, root: { EmptyView() })
	}
	
	public init(screen: Screen, coordinator: HarmonyCoordinator<Screen>? = nil) {
		let coordinator = coordinator ?? HarmonyCoordinator<Screen>()
		coordinator.suppliesRoot = true
		self.root = EmptyView()
		coordinator.show(screen, config: .init(action: .push))
		_coordinator = State(initialValue: coordinator)
	}
}
