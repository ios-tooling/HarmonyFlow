//
//  HarmonyAction.swift
//  Harmony
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI

public enum HarmonyAction: Hashable, Equatable, Codable {
	case push        			   // navigation stack
	case bottomSheet		      // presentation modal
	case partialModal          // presentation modal
	case fullScreenModal       // presentation modal


	var isSheet: Bool {
		#if os(macOS)
			if self == .fullScreenModal { return true }
		#endif
		return self == .partialModal || self == .bottomSheet
	}
}

#if os(iOS)
extension HarmonyAction {
	var detents: Set<PresentationDetent> {
		switch self {
		case .bottomSheet: [.fraction(1.0 / 3.0)]
		case .partialModal: [.medium]
		case .push, .fullScreenModal: [.large]
		}
	}
}
#endif
