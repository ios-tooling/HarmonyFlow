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
	@ViewBuilder var label: TabLabel { get }
}
