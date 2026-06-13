//
//  HarmonyFlowTab.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI

public protocol HarmonyTab: Hashable, CaseIterable {
	associatedtype Screen: HarmonyScreen
	associatedtype TabLabel: View

	var rootScreen: Screen { get }
	@MainActor @ViewBuilder var label: TabLabel { get }
}
