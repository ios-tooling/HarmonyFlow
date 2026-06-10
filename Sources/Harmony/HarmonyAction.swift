//
//  HarmonyAction.swift
//  Harmony
//
//  Created by Ben Gottlieb on 6/9/26.
//

import Foundation

public enum HarmonyAction: Hashable, Equatable {
    case push           // navigation stack
    case modal          // presentation modal
}
