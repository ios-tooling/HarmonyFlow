//
//  HarmonySplitCoordinatorTests.swift
//  Harmony
//
//  Created by Ben Gottlieb on 6/11/26.
//

import Testing
import SwiftUI
@testable import Harmony

@MainActor
struct HarmonySplitCoordinatorTests {
	@Test func twoColumnSplitHasNoContentColumn() {
		let split = HarmonySplitCoordinator(sidebar: TestScreen.home, detail: .detail)
		#expect(split.contentCoordinator == nil)
		#expect(split.sidebarCoordinator.root == .home)
		#expect(split.detailCoordinator.root == .detail)
	}

	@Test func threeColumnSplitKeepsAllColumns() {
		let split = HarmonySplitCoordinator(sidebar: TestScreen.home, content: .detail, detail: .settings)
		#expect(split.contentCoordinator?.root == .detail)
	}

	@Test func showDetailReplacesTheDetailStack() {
		// selection navigation resets the detail column, dropping any pushed screens
		let split = HarmonySplitCoordinator(sidebar: TestScreen.home, detail: .detail)
		split.detailCoordinator.push(.settings)
		split.showDetail(.home)
		#expect(split.detailCoordinator.root == .home)
		#expect(split.detailCoordinator.fullPath.isEmpty)
	}

	@Test func columnsNavigateIndependently() {
		let split = HarmonySplitCoordinator(sidebar: TestScreen.home, detail: .detail)
		split.sidebarCoordinator.push(.settings)
		#expect(split.detailCoordinator.fullPath.isEmpty)
		split.detailCoordinator.partialModal(.settings)
		#expect(split.sidebarCoordinator.modalCoordinator == nil)
	}
}
