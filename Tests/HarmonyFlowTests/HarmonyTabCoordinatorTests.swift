//
//  HarmonyTabCoordinatorTests.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/11/26.
//

import Testing
import SwiftUI
@testable import HarmonyFlow

enum TestTab: String, HarmonyTab, Codable {
	case home, profile

	var rootScreen: any HarmonyDestination {
		switch self {
		case .home: TestScreen.home
		case .profile: TestScreen.settings
		}
	}

	var label: some View { Text(rawValue) }
}

@MainActor
struct HarmonyTabCoordinatorTests {
	@Test func eachTabKeepsItsOwnStack() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).push(TestScreen.detail)
		#expect(tabs.coordinator(for: .home).path == [.detail])
		#expect(tabs.coordinator(for: .profile).path.isEmpty)
	}

	@Test func tabCoordinatorsAreStable() {
		// per-tab navigation state survives tab switches because the same
		// coordinator instance is always returned
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		let profile = tabs.coordinator(for: .profile)
		tabs.selectedTab = .profile
		tabs.selectedTab = .home
		#expect(tabs.coordinator(for: .profile) === profile)
	}

	@Test func showInTabSwitchesAndPushes() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.show(TestScreen.detail, in: .profile)
		#expect(tabs.selectedTab == .profile)
		#expect(tabs.coordinator(for: .profile).path == [.detail])
	}

	@Test func showInTabHonorsPresentationConfig() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.show(TestScreen.detail, in: .profile, config: .init(action: .partialModal))
		#expect(tabs.selectedTab == .profile)
		#expect(tabs.coordinator(for: .profile).sheetCoordinator?.root == .detail)
	}

	@Test func showPushInAnotherTabClosesTheEarlierTabsModal() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.show(TestScreen.home, in: .home, config: .init(action: .partialModal))
		tabs.show(TestScreen.detail, in: .profile)
		#expect(tabs.selectedTab == .profile)
		#expect(tabs.coordinator(for: .home).presentedModal == nil)
		#expect(tabs.coordinator(for: .profile).path == [.detail])
		#expect(tabs.topScreen == .detail)
	}

	@Test func showBottomSheetInAnotherTabClosesTheEarlierTabsModal() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.show(TestScreen.home, in: .home, config: .init(action: .partialModal))
		tabs.show(TestScreen.detail, in: .profile, config: .init(action: .bottomSheet))
		#expect(tabs.coordinator(for: .home).presentedModal == nil)
		#expect(tabs.presentedBottomSheet?.root == .detail)
	}

	@Test func showPushInTheSameTabLeavesItsOwnModal() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		let home = tabs.coordinator(for: .home)
		home.partialModal(TestScreen.settings)
		tabs.show(TestScreen.detail, in: .home)
		#expect(home.presentedModal != nil)
		#expect(home.path == [.detail])
	}

	@Test func showPushClosesAModalPresentedFromAnotherTabsBottomSheet() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).bottomSheet(TestScreen.detail)
		tabs.presentedBottomSheet?.partialModal(TestScreen.settings)
		#expect(tabs.presentedBottomSheet?.presentedModal != nil)
		tabs.show(TestScreen.detail, in: .profile)
		#expect(tabs.presentedBottomSheet != nil)
		#expect(tabs.presentedBottomSheet?.presentedModal == nil)
	}

	@Test func showModalInAnotherTabLeavesTheEarlierModalToSwiftUI() {
		// on screen SwiftUI replaces the earlier sheet and the coordinator follows through the sheet
		// binding; dismissing here too made UIKit log "Attempt to dismiss … while a presentation or
		// dismiss is in progress"
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).partialModal(TestScreen.settings)
		tabs.show(TestScreen.detail, in: .profile, config: .init(action: .partialModal))
		#expect(tabs.coordinator(for: .home).presentedModal != nil)
	}

	@Test func showPushInAnotherTabResumesAPendingPresentation() async {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		let home = tabs.coordinator(for: .home)
		async let pending: Int? = home.present(TestScreen.settings)
		while home.presentedModal == nil { await Task.yield() }
		tabs.show(TestScreen.detail, in: .profile)
		let result = await pending
		#expect(result == nil)
	}

	@Test func tabBottomSheetsHoistToTabCoordinator() {
		// bottom sheets render above the tab bar, so the tab coordinator hosts them
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).bottomSheet(TestScreen.detail)
		#expect(tabs.bottomSheetCoordinator?.root == .detail)
		#expect(tabs.coordinator(for: .home).bottomSheetCoordinator == nil)
	}

	@Test func tabBottomSheetsReplaceAcrossTabs() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).bottomSheet(TestScreen.detail)
		let first = tabs.bottomSheetCoordinator
		tabs.coordinator(for: .profile).bottomSheet(TestScreen.settings)
		#expect(tabs.bottomSheetCoordinator !== first)
		#expect(tabs.bottomSheetCoordinator?.root == .settings)
	}

	@Test func tabBottomSheetDismissStackClearsTabSlot() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).bottomSheet(TestScreen.detail)
		tabs.bottomSheetCoordinator?.dismissStack()
		#expect(tabs.bottomSheetCoordinator == nil)
	}

	@Test func modalBottomSheetsStayInTheirModal() {
		// a bottom sheet inside a modal belongs to the modal (which covers the tab
		// bar anyway), not to the tab-level layer
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).partialModal(TestScreen.settings)
		tabs.coordinator(for: .home).modalCoordinator?.bottomSheet(TestScreen.detail)
		#expect(tabs.coordinator(for: .home).modalCoordinator?.bottomSheetCoordinator?.root == .detail)
		#expect(tabs.bottomSheetCoordinator == nil)
	}

	@Test func bottomSheetFromTabLevelSheetReplacesIt() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).bottomSheet(TestScreen.detail)
		let first = tabs.bottomSheetCoordinator
		first?.bottomSheet(TestScreen.settings)
		#expect(tabs.bottomSheetCoordinator !== first)
		#expect(tabs.bottomSheetCoordinator?.root == .settings)
	}

	@Test func collapseReturnsSelectedTabToItsRoot() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).push(TestScreen.detail)
		tabs.coordinator(for: .home).partialModal(TestScreen.settings)
		tabs.collapse()
		#expect(tabs.coordinator(for: .home).path.isEmpty)
		#expect(tabs.coordinator(for: .home).modalCoordinator == nil)
	}

	@Test func collapseLeavesOtherTabsAlone() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .profile).push(TestScreen.detail)
		tabs.coordinator(for: .home).push(TestScreen.detail)
		tabs.collapse(.home)
		#expect(tabs.coordinator(for: .home).path.isEmpty)
		#expect(tabs.coordinator(for: .profile).path == [.detail])
	}

	@Test func plainCoordinatorsHostTheirOwnBottomSheets() {
		// standalone coordinators (e.g. inside a vanilla TabView) keep bottom sheets
		// local — no tab coordinator required
		let one = HarmonyCoordinator(TestScreen.home)
		let two = HarmonyCoordinator(TestScreen.settings)
		one.bottomSheet(TestScreen.detail)
		#expect(one.bottomSheetCoordinator?.root == .detail)
		#expect(two.bottomSheetCoordinator == nil)
	}
}
