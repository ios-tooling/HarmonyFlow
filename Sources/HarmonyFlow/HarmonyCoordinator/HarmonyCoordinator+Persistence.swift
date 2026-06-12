//
//  HarmonyFlowCoordinator+Persistence.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/12/26.
//

import Foundation

// optional capability: screen types that also conform to Codable get
// whole-tree state persistence, with no requirements on those that don't
struct HarmonySnapshot<Screen: HarmonyScreen & Codable>: Codable {
	var root: Screen
	var path: [Screen]
	var configuration: HarmonyNavigationConfiguration
	var modal: [HarmonySnapshot]		// 0 or 1 elements; an array only to break struct recursion
	var bottomSheet: [HarmonySnapshot]
}

extension HarmonyCoordinator where Screen: Codable {
	var snapshot: HarmonySnapshot<Screen> {
		HarmonySnapshot(
			root: root,
			path: fullPath,
			configuration: configuration,
			modal: modalCoordinator.map { [$0.snapshot] } ?? [],
			bottomSheet: bottomSheetCoordinator.map { [$0.snapshot] } ?? []
		)
	}

	public func encodedState() throws -> Data {
		try JSONEncoder().encode(snapshot)
	}

	public convenience init(restoring data: Data) throws {
		let snapshot = try JSONDecoder().decode(HarmonySnapshot<Screen>.self, from: data)
		self.init(snapshot: snapshot)
	}

	convenience init(snapshot: HarmonySnapshot<Screen>) {
		self.init([snapshot.root] + snapshot.path)
		configuration = snapshot.configuration

		if let modal = snapshot.modal.first {
			let child = HarmonyCoordinator(snapshot: modal)
			child.parentCoordinator = self
			modalCoordinator = child
		}

		if let sheet = snapshot.bottomSheet.first {
			let child = HarmonyCoordinator(snapshot: sheet)
			child.parentCoordinator = self
			bottomSheetCoordinator = child
		}
	}
}
