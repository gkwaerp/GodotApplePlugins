//
//  AppleLeaderboard.swift
//  GodotApplePlugins
//
//  Created by Miguel de Icaza on 11/15/25.
//
@preconcurrency import SwiftGodotRuntime
import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

import GameKit

enum AppleLeaderboardType: Int, CaseIterable {
    case classic
    case recurring
    case unknown
}

@Godot
class GKLeaderboard: RefCounted, @unchecked Sendable {
    var board: GameKit.GKLeaderboard = GameKit.GKLeaderboard()

    convenience init(board: GameKit.GKLeaderboard) {
        self.init()
    }

    @Export var title: String { board.title ?? "" }
    @Export(.enum) var type: AppleLeaderboardType {
        switch board.type {
        case .classic: return .classic
        case .recurring: return .recurring
        default: return .unknown
        }
    }

    @Export var groupIdentifier: String { board.groupIdentifier ?? "" }
    @Export var activityIdentifier: String {
        if #available(iOS 26.0, macOS 26.0, *) {
            return board.activityIdentifier
        } else {
            return ""
        }
    }
    @Export var activityProperties: VariantDictionary {
        if #available(iOS 26.0, macOS 26.0, *) {
            let result = VariantDictionary()
            for (key, value) in board.activityProperties {
                result[Variant(key)] = Variant(value)
            }
            return result
        } else {
            return VariantDictionary()
        }
    }
    // Not sure how to surface dates to Godot
    //@Export var startDate:
    //@Export var endDate:
    @Export var duration: Double { board.duration }

    @Callable
    /// Callback is invoked with nil on success, or a string on error
    func submit_score(score: Int, context: Int, player: GKPlayer, callback: Callable) {
        board.submitScore(score, context: context, player: player.player) { error in
            let result: Variant?
            if let error {
                result = Variant(error.localizedDescription)
            } else {
                result = nil
            }
            _ = callback.call(result)
        }
    }

    /// Loads the image for the leaderboard, the call back is invoked with two arguments
    /// a PackedByteArray with the image as the first argument, an any error as the second.
    /// either one can be nil.
    @Callable()
    func load_image(callback: Callable) {
        board.loadImage { image, error in
            if let image, let png = image.pngData() {
                let array = PackedByteArray([UInt8](png))
                _ = callback.call(Variant(array), nil)
            } else if let error {
                _ = callback.call(nil, Variant(error.localizedDescription))
            } else {
                _ = callback.call(nil Variant("Could not load leaderboard image"))
            }
        }
    }

    @Callable
    static func load_leaderboards(_ ids: PackedStringArray, callback: Callable) {
        var sids: [String]?
        if ids.count == 0 {
            sids = nil
        } else {
            var result: [String] = []
            for x in 0..<ids.count {
                result.append(ids[x])
            }
            sids = result
        }
        GameKit.GKLeaderboard.loadLeaderboards(IDs: sids) { result, error in
            let wrapped = VariantArray()
            if let error {
                _ callback.call(nil, Variant(String(describing: error)))
            } else if let result {
                for l in result {
                    let wrap = GKLeaderboard(board: l)
                    wrapped.append(Variant(wrap))
                }
            }
            _ = callback.call(Variant(wrapped), nil)
        } else {
            _ = callback.call(Variant(VariantArray()), nil)
        }
    }
}
