//
//  HarmonyNavigationConfigurationx.swift
//  Harmony
//
//  Created by Ben Gottlieb on 6/9/26.
//

import Foundation

public struct HarmonyNavigationConfiguration {
    public var action: HarmonyAction
    public var priority: Double
    
    public init(action: HarmonyAction, priority: Double = 0.5) {
        self.action = action
        self.priority = priority
    }
}
