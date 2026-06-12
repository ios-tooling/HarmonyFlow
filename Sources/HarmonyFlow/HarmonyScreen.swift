//
//  HarmonyFlowScreen.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI

public protocol HarmonyScreen: Hashable, Identifiable, Equatable {
    associatedtype Body: View
    
	@ViewBuilder func body(configuration: HarmonyCoordinator<Self>.ScreenConfiguration) -> Body
}
