//
//  AppleLeaderboardSets.swift
//  GodotApplePlugins
//
//  Created by Miguel de Icaza on 11/16/25.
//

@preconcurrency import SwiftGodotRuntime
import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
import GameKit

@Godot
class AppleLeaderboardSet: RefCounted, @unchecked Sendable {
    var boardset = GKLeaderboardSet()

    convenience init?(boardset: GKLeaderboardSet) {
        self.init()
        self.boardset = boardset
    }
}
