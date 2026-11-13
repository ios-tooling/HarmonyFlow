//
//  HarmonyPresentationPacer.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 11/13/26.
//

import Foundation

// UIKit refuses a modal presentation requested while another modal transition is still in flight, and SwiftUI
// never retries it, which would leave the coordinator listing a flow that is not on screen. So modals take
// turns: the first goes straight on screen, and one requested while a transition is in flight is held
// (HarmonyCoordinator.isHeld) until that transition has had time to finish. Dismissals, pushes and bottom
// sheets are not held. One pacer serves the whole process, because sibling stacks (tabs, split columns,
// separate HarmonyStacks) share the window's single presentation chain.
@MainActor final class HarmonyPresentationPacer {
	static let shared = HarmonyPresentationPacer()

	private let presentationSettle: Duration
	private let dismissalSettle: Duration
	private var settlesAt: ContinuousClock.Instant?		// when the transition in flight will have finished
	private(set) var waiting: [HarmonyCoordinator] = []
	private var admission: Task<Void, Never>?

	init(presentationSettle: Duration = .seconds(1), dismissalSettle: Duration = .milliseconds(600)) {
		self.presentationSettle = presentationSettle
		self.dismissalSettle = dismissalSettle
	}

	private var isSettled: Bool { settlesAt.map { $0 <= .now } ?? true }

	// a modal has just started going on screen / coming off it
	func notePresentation() { hold(for: presentationSettle) }
	func noteDismissal() { hold(for: dismissalSettle) }

	private func hold(for duration: Duration) {
		settlesAt = max(settlesAt ?? .now, ContinuousClock.now.advanced(by: duration))
	}

	// the modal was just presented in the model: it goes on screen at once if nothing is in flight, else in turn
	func pace(_ modal: HarmonyCoordinator) {
		guard !isSettled || !waiting.isEmpty else { notePresentation(); return }
		modal.isHeld = true
		waiting.append(modal)
		if admission == nil { admission = Task { await admitWaiting() } }
	}

	// the modal left the model: a held one gives up its turn, a shown one is on its way off screen
	func modalRemoved(_ modal: HarmonyCoordinator) {
		guard modal.isHeld else { noteDismissal(); return }
		modal.isHeld = false
		waiting.removeAll { $0 === modal }
	}

	private func admitWaiting() async {
		while !waiting.isEmpty {
			if let settlesAt, settlesAt > .now {
				try? await Task.sleep(until: settlesAt, clock: .continuous)
				continue
			}
			waiting.removeFirst().isHeld = false
			notePresentation()
		}
		admission = nil
	}
}
