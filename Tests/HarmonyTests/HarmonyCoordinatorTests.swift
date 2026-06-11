//
//  HarmonyCoordinatorTests.swift
//  Harmony
//
//  Created by Ben Gottlieb on 6/10/26.
//

import Testing
import SwiftUI
@testable import Harmony

enum TestScreen: String, HarmonyScreen {
	case home, detail, settings

	var id: String { rawValue }

	func body(configuration: HarmonyCoordinator<Self>.ScreenConfiguration) -> some View {
		Text(rawValue)
	}
}

@MainActor
struct HarmonyCoordinatorTests {
	@Test func coordinatorsHaveDistinctIDs() {
		// sheet(item:) keys presentation identity off `id`; duplicate ids break re-presentation
		let a = HarmonyCoordinator(TestScreen.home)
		let b = HarmonyCoordinator(TestScreen.home)
		#expect(a.id != b.id)
	}

	@Test func pushAppendsToPath() {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.push(.detail)
		#expect(coordinator.fullPath == [.detail])
	}

	@Test func pathBindingRecordsExternalPushes() {
		// NavigationLink(value:) writes through the binding; the coordinator must not revert it
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.pathBinding.wrappedValue.append(.detail)
		#expect(coordinator.fullPath == [.detail])
	}

	@Test func pathBindingPopsScreens() {
		let coordinator = HarmonyCoordinator([TestScreen.home, .detail, .settings])
		coordinator.pathBinding.wrappedValue.removeLast()
		#expect(coordinator.fullPath == [.detail])
	}

	@Test func partialModalCreatesSheetChild() {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.partialModal(.settings)
		#expect(coordinator.sheetCoordinator?.root == .settings)
		#expect(coordinator.fullScreenCoordinator == nil)
		#expect(coordinator.fullPath.isEmpty)
	}

	@Test func fullScreenModalCreatesFullScreenChild() {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.fullScreenModal(.settings)
		#if os(iOS)
		#expect(coordinator.fullScreenCoordinator?.root == .settings)
		#expect(coordinator.sheetCoordinator == nil)
		#else
		// macOS has no full-screen covers; fullScreenModal presents as a sheet
		#expect(coordinator.sheetCoordinator?.root == .settings)
		#expect(coordinator.fullScreenCoordinator == nil)
		#endif
	}

	@Test func dismissPopsPushedScreenFirst() {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.push(.detail)
		coordinator.dismiss()
		#expect(coordinator.fullPath.isEmpty)
	}

	@Test func presentationConfigIsStoredOnPresentedCoordinator() {
		// per-screen presentation options must survive to the child coordinator,
		// where HarmonyStack reads them at presentation time
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.show(.settings, config: .init(action: .partialModal, detents: [.fraction(0.75)], isInteractiveDismissDisabled: true))
		#expect(parent.sheetCoordinator?.configuration.detents == [.fraction(0.75)])
		#expect(parent.sheetCoordinator?.configuration.isInteractiveDismissDisabled == true)
	}

	#if os(iOS)
	@Test func detentsFallBackToActionDefaultsWhenUnspecified() {
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.partialModal(.settings)
		#expect(parent.sheetCoordinator?.presentationDetents == [.medium])
	}

	@Test func customDetentsOverrideActionDefaults() {
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.show(.settings, config: .init(action: .partialModal, detents: [.height(200), .large]))
		#expect(parent.sheetCoordinator?.presentationDetents == [.height(200), .large])
	}
	#endif

	@Test func dismissStackRemovesWholePresentedStack() {
		// a screen deep inside a presented flow can close the entire flow,
		// without knowing how it was presented
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.partialModal(.settings)
		let sheet = parent.sheetCoordinator
		sheet?.push(.detail)
		sheet?.push(.home)
		sheet?.dismissStack()
		#expect(parent.sheetCoordinator == nil)
	}

	@Test func dismissStackAtRootDoesNothing() {
		let coordinator = HarmonyCoordinator([TestScreen.home, .detail])
		coordinator.dismissStack()
		#expect(coordinator.fullPath == [.detail])
	}

	@Test func dismissOnPresentedRootRemovesItFromParent() {
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.bottomSheet(.settings)
		parent.sheetCoordinator?.dismiss()
		#expect(parent.sheetCoordinator == nil)
	}

	@Test func sheetBindingNilOnlyClearsSheetChildren() {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.fullScreenModal(.settings)
		coordinator.sheetCoordinator = nil
		#if os(iOS)
		// SwiftUI writes nil through inactive presentation bindings during updates;
		// a sheet dismissal must not tear down a full-screen child
		#expect(coordinator.fullScreenCoordinator != nil)
		#else
		// on macOS fullScreenModal presents as a sheet, so the sheet binding owns its dismissal
		#expect(coordinator.modalCoordinator == nil)
		#endif
	}

	@Test func fullScreenBindingNilOnlyClearsFullScreenChildren() {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.partialModal(.settings)
		coordinator.fullScreenCoordinator = nil
		#expect(coordinator.sheetCoordinator != nil)
	}

	@Test func bottomSheetPersistsUnderModal() {
		// a bottom sheet is a persistent layer; presenting a modal must not destroy it
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.bottomSheet(.detail)
		parent.partialModal(.settings)
		#expect(parent.bottomSheetCoordinator?.root == .detail)
		#expect(parent.sheetCoordinator?.root == .settings)
	}

	@Test func modalDismissalRevealsBottomSheet() {
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.bottomSheet(.detail)
		parent.partialModal(.settings)
		parent.sheetCoordinator = nil
		#expect(parent.bottomSheetCoordinator?.root == .detail)
		#expect(parent.sheetCoordinator?.root == .detail)
	}

	@Test func dismissStackClearsOnlyItsOwnSlot() {
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.bottomSheet(.detail)
		parent.partialModal(.settings)
		parent.bottomSheetCoordinator?.dismissStack()
		#expect(parent.bottomSheetCoordinator == nil)
		#expect(parent.sheetCoordinator?.root == .settings)
	}

	#if os(iOS)
	@Test func fullScreenModalSuppressesBottomSheetPresentation() {
		// sheet(item:) and fullScreenCover(item:) can't present simultaneously from one
		// view; while a cover is up the sheet binding must stay nil — but the bottom
		// sheet itself survives for when the cover dismisses
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.bottomSheet(.detail)
		parent.fullScreenModal(.settings)
		#expect(parent.sheetCoordinator == nil)
		#expect(parent.bottomSheetCoordinator != nil)
	}
	#endif
}
