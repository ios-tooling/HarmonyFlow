//
//  HarmonyPresentationPacerTests.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 11/13/26.
//

import Testing
@testable import HarmonyFlow

// durations are asserted as lower bounds only, so a loaded machine cannot make these flake
@MainActor
struct HarmonyPresentationPacerTests {
	func makePacer() -> HarmonyPresentationPacer { HarmonyPresentationPacer(presentationSettle: .milliseconds(200), dismissalSettle: .milliseconds(100)) }

	func makeModal() -> HarmonyCoordinator {
		let modal = HarmonyCoordinator(TestScreen.detail)
		modal.configuration = .init(action: .partialModal)
		return modal
	}

	func shown(_ modal: HarmonyCoordinator) async {
		while modal.isHeld { try? await Task.sleep(for: .milliseconds(5)) }
	}

	@Test func firstModalGoesStraightOnScreen() {
		let pacer = makePacer()
		let a = makeModal()
		pacer.pace(a)
		#expect(!a.isHeld)
	}

	@Test func modalRequestedMidTransitionWaitsForItToSettle() async {
		let pacer = makePacer()
		let a = makeModal(), b = makeModal()
		let elapsed = await ContinuousClock().measure {
			pacer.pace(a)
			pacer.pace(b)
			#expect(b.isHeld)
			await shown(b)
		}
		#expect(elapsed >= .milliseconds(180))
	}

	@Test func heldModalsGoOnScreenInOrder() async {
		let pacer = makePacer()
		let a = makeModal(), b = makeModal(), c = makeModal()
		let elapsed = await ContinuousClock().measure {
			pacer.pace(a)
			pacer.pace(b)
			pacer.pace(c)
			await shown(b)
			#expect(c.isHeld)
			await shown(c)
		}
		#expect(elapsed >= .milliseconds(380))
	}

	@Test func removedHeldModalGivesUpItsTurn() async {
		let pacer = makePacer()
		let a = makeModal(), b = makeModal(), c = makeModal()
		pacer.pace(a)
		pacer.pace(b)
		pacer.pace(c)
		pacer.modalRemoved(b)
		#expect(!b.isHeld)
		#expect(!pacer.waiting.contains { $0 === b })
		await shown(c)
		#expect(pacer.waiting.isEmpty)
	}

	@Test func dismissalHoldsTheNextModalBriefly() async {
		let pacer = makePacer()
		let x = makeModal(), c = makeModal()
		let elapsed = await ContinuousClock().measure {
			pacer.modalRemoved(x)
			pacer.pace(c)
			#expect(c.isHeld)
			await shown(c)
		}
		#expect(elapsed >= .milliseconds(90))
	}

	// the shared pacer: immediate assertions only, never waiting on its real settle
	@Test func modalPresentedMidTransitionIsHeldButStillListed() {
		HarmonyPresentationPacer.shared.notePresentation()
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.partialModal(TestScreen.settings)
		#expect(parent.modalCoordinator?.isHeld == true)
		#expect(parent.shownSheetCoordinator == nil)
		#expect(parent.sheetCoordinator?.root == .settings)
		#expect(parent.screens == [.home, .settings])
	}

	@Test func swiftUINilWritesAreIgnoredWhileTheModalIsHeld() {
		HarmonyPresentationPacer.shared.notePresentation()
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.partialModal(TestScreen.settings)
		parent.shownSheetCoordinator = nil
		parent.shownFullScreenCoordinator = nil
		#expect(parent.modalCoordinator != nil)
	}

	@Test func dismissingAHeldModalGivesUpItsTurn() {
		HarmonyPresentationPacer.shared.notePresentation()
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.partialModal(TestScreen.settings)
		let modal = parent.modalCoordinator
		#expect(modal?.isHeld == true)
		parent.dismissTopFlow()
		#expect(modal?.isHeld == false)
		#expect(!HarmonyPresentationPacer.shared.waiting.contains { $0 === modal })
	}

	@Test func shownModalStillClearsThroughItsBinding() {
		HarmonyPresentationPacer.shared.notePresentation()
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.partialModal(TestScreen.settings)
		parent.modalCoordinator?.isHeld = false		// standing in for its turn having come
		parent.shownSheetCoordinator = nil
		#expect(parent.modalCoordinator == nil)
	}
}
