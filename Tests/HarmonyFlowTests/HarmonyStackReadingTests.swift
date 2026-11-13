//
//  HarmonyStackReadingTests.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 11/12/26.
//

import Testing
import Observation
import HarmonyFlow

// deliberately not @testable: everything touched here must be public API
@MainActor
struct HarmonyStackReadingTests {
	@Test func rootAndPathAreReadable() {
		let coordinator = HarmonyCoordinator([TestScreen.home, .detail, .settings])
		#expect(coordinator.root == .home)
		#expect(coordinator.path == [.detail, .settings])
		#expect(coordinator.screens == [.home, .detail, .settings])
		#expect(coordinator.topScreen == .settings)
	}

	@Test func destinationsCastBackToTheirOwnType() {
		let coordinator = HarmonyCoordinator([TestScreen.home, .settings])
		#expect(coordinator.topScreen.destination as? TestScreen == .settings)
	}

	@Test func screensRunFromTheRootUpThroughPresentedFlows() {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.push(TestScreen.detail)
		coordinator.partialModal(TestScreen.settings)
		coordinator.presentedModal?.push(TestScreen.detail)
		#expect(coordinator.screens == [.home, .detail, .settings, .detail])
		#expect(coordinator.topScreen == .detail)
		#expect(coordinator.topCoordinator === coordinator.presentedModal)
	}

	@Test func modalReadsAboveBottomSheet() {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.bottomSheet(TestScreen.detail)
		#expect(coordinator.topCoordinator === coordinator.presentedBottomSheet)
		coordinator.partialModal(TestScreen.settings)
		#expect(coordinator.screens == [.home, .detail, .settings])
		#expect(coordinator.topScreen == .settings)
		#expect(coordinator.topCoordinator === coordinator.presentedModal)
	}

	@Test func topCoordinatorFollowsNestedPresentations() {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		#expect(coordinator.topCoordinator === coordinator)
		coordinator.partialModal(TestScreen.settings)
		coordinator.presentedModal?.fullScreenModal(TestScreen.detail)
		let inner = coordinator.presentedModal?.presentedModal
		#expect(inner != nil)
		#expect(coordinator.topCoordinator === inner)
	}

	@Test func dismissTopFlowRemovesOnlyTheFrontmostFlow() {
		let coordinator = HarmonyCoordinator([TestScreen.home, .detail])
		coordinator.partialModal(TestScreen.settings)
		let modalA = coordinator.presentedModal
		modalA?.push(TestScreen.detail)
		modalA?.partialModal(TestScreen.home)

		#expect(coordinator.dismissTopFlow())
		#expect(coordinator.presentedModal === modalA)
		#expect(modalA?.presentedModal == nil)
		#expect(modalA?.path == [.detail])
		#expect(coordinator.path == [.detail])

		#expect(coordinator.dismissTopFlow())
		#expect(coordinator.presentedModal == nil)
		#expect(coordinator.path == [.detail])

		#expect(!coordinator.dismissTopFlow())
		#expect(coordinator.path == [.detail])
	}

	@Test func dismissTopFlowResumesAPendingPresentation() async {
		let parent = HarmonyCoordinator(TestScreen.home)
		async let pending: Int? = parent.present(TestScreen.settings)
		while parent.presentedModal == nil { await Task.yield() }
		parent.dismissTopFlow()
		let result = await pending
		#expect(result == nil)
	}

	@Test func screensAreObservedThroughAPush() async {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		await confirmation { changed in
			withObservationTracking { _ = coordinator.screens } onChange: { changed() }
			coordinator.push(TestScreen.detail)
		}
	}

	@Test func screensAreObservedThroughAModalPresentation() async {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		await confirmation { changed in
			withObservationTracking { _ = coordinator.screens } onChange: { changed() }
			coordinator.partialModal(TestScreen.settings)
		}
	}

	@Test func screensAreObservedThroughAPushInsideAPresentedModal() async {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.partialModal(TestScreen.settings)
		await confirmation { changed in
			withObservationTracking { _ = coordinator.screens } onChange: { changed() }
			coordinator.presentedModal?.push(TestScreen.detail)
		}
	}
}
