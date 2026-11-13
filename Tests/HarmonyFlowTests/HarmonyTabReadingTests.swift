//
//  HarmonyTabReadingTests.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 11/12/26.
//

import Testing
import Observation
import HarmonyFlow

// deliberately not @testable: everything touched here must be public API
@MainActor
struct HarmonyTabReadingTests {
	@Test func tabScreensIncludeItsHoistedBottomSheet() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).bottomSheet(TestScreen.detail)
		#expect(tabs.coordinator(for: .home).screens == [.home, .detail])
		#expect(tabs.coordinator(for: .home).presentedBottomSheet?.root == .detail)
		#expect(tabs.presentedBottomSheet?.root == .detail)
	}

	@Test func hoistedBottomSheetIsReportedOnlyByItsPresentingTab() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).bottomSheet(TestScreen.detail)
		#expect(tabs.coordinator(for: .profile).screens == [.settings])
		#expect(tabs.coordinator(for: .profile).presentedBottomSheet == nil)
		#expect(tabs.presentedBottomSheet != nil)
		#expect(tabs.presentedBottomSheet?.presentedBottomSheet == nil)
	}

	@Test func dismissTopFlowInTabLeavesItsPathAlone() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		let home = tabs.coordinator(for: .home)
		home.push(TestScreen.detail)
		home.fullScreenModal(TestScreen.settings)
		#expect(tabs.dismissTopFlow(in: .home))
		#expect(home.path == [.detail])
		#expect(home.presentedModal == nil)
	}

	@Test func dismissTopFlowDefaultsToTheSelectedTab() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.profile)
		tabs.coordinator(for: .home).partialModal(TestScreen.detail)
		tabs.coordinator(for: .profile).partialModal(TestScreen.detail)
		#expect(tabs.dismissTopFlow())
		#expect(tabs.coordinator(for: .profile).presentedModal == nil)
		#expect(tabs.coordinator(for: .home).presentedModal != nil)
	}

	@Test func dismissTopFlowClosesAHoistedBottomSheet() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).bottomSheet(TestScreen.detail)
		#expect(tabs.dismissTopFlow())
		#expect(tabs.presentedBottomSheet == nil)
		#expect(!tabs.dismissTopFlow())
	}

	@Test func topScreenIsTheSelectedTabsTopWhenNothingIsPresented() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).push(TestScreen.detail)
		#expect(tabs.topScreen == .detail)
		#expect(tabs.topCoordinator === tabs.coordinator(for: .home))
		tabs.selectedTab = .profile
		#expect(tabs.topScreen == .settings)
	}

	@Test func topCoordinatorFollowsTheSelectedTabsModal() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		let home = tabs.coordinator(for: .home)
		home.partialModal(TestScreen.settings)
		home.presentedModal?.push(TestScreen.detail)
		#expect(tabs.topCoordinator === home.presentedModal)
		#expect(tabs.topScreen == .detail)
	}

	@Test func modalFromAnUnselectedTabStaysOnTop() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).partialModal(TestScreen.detail)
		tabs.selectedTab = .profile
		#expect(tabs.topCoordinator === tabs.coordinator(for: .home).presentedModal)
		#expect(tabs.topScreen == .detail)
		#expect(tabs.coordinator(for: .profile).topScreen == .settings)
	}

	@Test func selectedTabsModalWinsOverAnotherTabs() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.profile)
		tabs.coordinator(for: .home).partialModal(TestScreen.detail)
		tabs.coordinator(for: .profile).partialModal(TestScreen.home)
		#expect(tabs.topCoordinator === tabs.coordinator(for: .profile).presentedModal)
		#expect(tabs.topScreen == .home)
	}

	@Test func bottomSheetAboveTheTabBarIsOnTopInEveryTab() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).bottomSheet(TestScreen.detail)
		tabs.selectedTab = .profile
		#expect(tabs.topCoordinator === tabs.presentedBottomSheet)
		tabs.coordinator(for: .profile).partialModal(TestScreen.home)
		#expect(tabs.topCoordinator === tabs.coordinator(for: .profile).presentedModal)
		#expect(tabs.topScreen == .home)
	}

	@Test func topScreenIsObservedThroughAnotherTabsModal() async {
		let tabs = HarmonyTabCoordinator(selected: TestTab.profile)
		let home = tabs.coordinator(for: .home)
		await confirmation { changed in
			withObservationTracking { _ = tabs.topScreen } onChange: { changed() }
			home.partialModal(TestScreen.detail)
		}
	}

	@Test func hoistedBottomSheetIsObservedThroughItsTab() async {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		let home = tabs.coordinator(for: .home)
		await confirmation { changed in
			withObservationTracking { _ = tabs.coordinator(for: .home).screens } onChange: { changed() }
			home.bottomSheet(TestScreen.detail)
		}
	}
}
