//
//  HarmonyCoordinated.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/13/26.
//

import SwiftUI

/// Reads the enclosing ``HarmonyCoordinator`` from the environment.
///
/// `HarmonyStack`, `HarmonyTabs`, and `HarmonySplit` inject the coordinator, so
/// `wrappedValue` is non-optional and is the terse, official way to reach it:
///
/// ```swift
/// struct BackButton: View {
///     @HarmonyCoordinated<AppScreen> private var coordinator
///     var body: some View { Button("Back") { coordinator.dismiss() } }
/// }
/// ```
///
/// For the rare case where a view may render outside a container (e.g. a
/// standalone `#Preview`), use the projected value for optional access:
/// `$coordinator?.dismiss()`.
@propertyWrapper
public struct HarmonyCoordinated<Screen: HarmonyScreen>: DynamicProperty {
	@Environment(HarmonyCoordinator<Screen>.self) private var coordinator: HarmonyCoordinator<Screen>?

	public init() { }

	public var wrappedValue: HarmonyCoordinator<Screen> {
		guard let coordinator else {
			fatalError("@HarmonyCoordinated requires a HarmonyCoordinator<\(Screen.self)> in the environment — present this view through a HarmonyStack, HarmonyTabs, or HarmonySplit. Use the projected value ($coordinator) for optional access.")
		}
		return coordinator
	}

	public var projectedValue: HarmonyCoordinator<Screen>? { coordinator }
}
