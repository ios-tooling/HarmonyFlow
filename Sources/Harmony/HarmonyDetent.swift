//
//  HarmonyDetent.swift
//  Harmony
//
//  Created by Ben Gottlieb on 6/10/26.
//

import SwiftUI

public enum HarmonyDetent: Hashable, Sendable {
	case medium
	case large
	case fraction(Double)
	case height(Double)

	func resolvedHeight(in containerHeight: CGFloat) -> CGFloat {
		switch self {
		case .medium: containerHeight * 0.5
		case .large: containerHeight
		case .fraction(let fraction): containerHeight * fraction
		case .height(let height): height
		}
	}
}

#if os(iOS)
extension HarmonyDetent {
	var presentationDetent: PresentationDetent {
		switch self {
		case .medium: .medium
		case .large: .large
		case .fraction(let fraction): .fraction(fraction)
		case .height(let height): .height(height)
		}
	}
}

extension HarmonyCoordinator {
	var presentationDetents: Set<PresentationDetent> {
		if let detents = configuration.detents { return Set(detents.map(\.presentationDetent)) }
		return configuration.action.detents
	}
}
#endif
