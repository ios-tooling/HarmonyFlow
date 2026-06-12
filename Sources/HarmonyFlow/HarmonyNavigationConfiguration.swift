//
//  HarmonyFlowNavigationConfigurationx.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/9/26.
//

import Foundation

public struct HarmonyNavigationConfiguration: Codable {
    public var action: HarmonyAction
    public var detents: Set<HarmonyDetent>?
    public var isInteractiveDismissDisabled: Bool

    public init(action: HarmonyAction, detents: Set<HarmonyDetent>? = nil, isInteractiveDismissDisabled: Bool = false) {
        self.action = action
        self.detents = detents
        self.isInteractiveDismissDisabled = isInteractiveDismissDisabled
    }
}
