//
//  HarmonyPersistenceTests.swift
//  Harmony
//
//  Created by Ben Gottlieb on 6/12/26.
//

import Testing
import Foundation
@testable import Harmony

@MainActor
struct HarmonyPersistenceTests {
	@Test func stateRoundTripsThroughData() throws {
		let original = HarmonyCoordinator([TestScreen.home, .detail, .settings])
		let restored = try HarmonyCoordinator<TestScreen>(restoring: original.encodedState())
		#expect(restored.root == .home)
		#expect(restored.fullPath == [.detail, .settings])
	}

	@Test func presentedTreeSurvivesRoundTrip() throws {
		// the whole presentation tree persists: children, their paths, and their configs
		let original = HarmonyCoordinator(TestScreen.home)
		original.show(.settings, config: .init(action: .partialModal, detents: [.fraction(0.75)], isInteractiveDismissDisabled: true))
		original.sheetCoordinator?.push(.detail)

		let restored = try HarmonyCoordinator<TestScreen>(restoring: original.encodedState())
		#expect(restored.sheetCoordinator?.root == .settings)
		#expect(restored.sheetCoordinator?.fullPath == [.detail])
		#expect(restored.sheetCoordinator?.configuration.detents == [.fraction(0.75)])
		#expect(restored.sheetCoordinator?.configuration.isInteractiveDismissDisabled == true)
	}

	@Test func restoredChildrenCanDismiss() throws {
		// parent links must be rebuilt, not just the tree shape
		let original = HarmonyCoordinator(TestScreen.home)
		original.bottomSheet(.detail)
		let restored = try HarmonyCoordinator<TestScreen>(restoring: original.encodedState())
		restored.bottomSheetCoordinator?.dismissStack()
		#expect(restored.bottomSheetCoordinator == nil)
	}

	@Test func replacePathSwapsWholePath() {
		let coordinator = HarmonyCoordinator([TestScreen.home, .detail])
		coordinator.replacePath([.settings, .detail, .settings])
		#expect(coordinator.fullPath == [.settings, .detail, .settings])
	}
}
