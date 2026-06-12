//
//  ShowDetailButton.swift
//  HarmonyTestHarness
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI
import Harmony

struct ShowDetailButton: View {
	@Environment(HarmonySplitCoordinator<Screen>.self) private var split: HarmonySplitCoordinator<Screen>?
	@State private var count = 0

	var body: some View {
		if let split {
			Button("Show Detail #\(count + 1)") {
				count += 1
				split.showDetail(.titled("Detail #\(count)"))
			}
		}
	}
}
