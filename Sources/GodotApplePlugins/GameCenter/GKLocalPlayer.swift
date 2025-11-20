//
//  GKLocalPlayer.swift
//  GodotApplePlugins
//
//  Created by Miguel de Icaza on 11/17/25.
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
class GKLocalPlayer: GKPlayer, @unchecked Sendable {
    var local: GameKit.GKLocalPlayer

    required init(_ context: InitContext) {
        local = GameKit.GKLocalPlayer.local
        super.init(context)
        player = local
    }

    init() {
        local = GameKit.GKLocalPlayer.local
        super.init(player: GameKit.GKLocalPlayer.local)
    }

    @Export var isAuthenticated: Bool { local.isAuthenticated }
    @Export var isUnderage: Bool { local.isUnderage }
    @Export var isMultiplayerGamingRestricted: Bool { local.isMultiplayerGamingRestricted }
    @Export var isPersonalizedCommunicationRestricted: Bool { local.isPersonalizedCommunicationRestricted }

    func friendDispatch(_ callback: Callable, _ friends: [GameKit.GKPlayer]?, _ error: (any Error)?) {
        let array = TypedArray<GKPlayer?>()

        if let friends {
            for friend in friends {
                let gkplayer = GKPlayer(player: friend)
                array.append(gkplayer)
            }
        }

        _ = callback.call(Variant(array), mapError(error))
    }

    /// Loads the friends, the callback receives two arguments an `Array[GKPlayer]` and Variant
    /// if the variant value is not nil, it contains a string with the error message
    @Callable func load_friends(callback: Callable) {
        local.loadFriends { friends, error in
            self.friendDispatch(callback, friends, error)
        }
    }

    /// Loads the challengeable friends, the callback receives two arguments an array of GKPlayers and a String error
    /// either one can be null
    @Callable func load_challengeable_friends(callback: Callable) {
        local.loadChallengableFriends { friends, error in
            self.friendDispatch(callback, friends, error)
        }
    }

    /// Loads the recent friends, the callback receives two arguments an array of GKPlayers and a String error
    /// either one can be null
    @Callable func load_recent_friends(callback: Callable) {
        local.loadRecentPlayers  { friends, error in
            self.friendDispatch(callback, friends, error)
        }
    }

    /// You get two return values back a dictionary containing the result values and an error.
    ///
    /// If the error is not nil:
    /// - "url": The URL for the public encryption key.
    /// - "data": PackedByteArray containing verification signature that GameKit generates, or nil
    /// - "salt": PackedByteArray containing a random NSString that GameKit uses to compute the hash and randomize it.
    /// - "timestamp": Int with signature’s creation date and time timestamp
    ///
    @Callable
    func fetch_items_for_identity_verification_signature(callback: Callable) {
        local.fetchItems { url, data, salt, timestamp, error in
            let result = VariantDictionary();

            if error == nil {
                let encodeData = data?.toPackedByteArray()
                let encodeSalt = salt?.toPackedByteArray()

                result["url"] = (Variant(url?.description ?? ""))
                result["data"]  = encodeData != nil ? Variant(encodeData) : nil
                result["salt"] = encodeSalt != nil ? Variant(encodeSalt) : nil
                result["timestamp"] = Variant(timestamp)
            }
            _ = callback.call(Variant(result), mapError(error))
        }
    }

    @Callable
    func save_game_data(data: PackedByteArray, withName: String, callback: Callable) {
        guard let converted = data.asData() else {
            _ = callback.call(nil, Variant(String("Could not convert the packed array to Data)")))
            return
        }
        local.saveGameData(converted, withName: withName) { savedGame, error in
            var savedV: Variant? = nil
            if let savedGame = savedGame {
                savedV = Variant(GKSavedGame(saved: savedGame))
            }
            _ = callback.call(savedV, mapError(error))
        }
    }

    @Callable
    func fetch_saved_games(callback: Callable) {
        local.fetchSavedGames { savedGames, error in
            let ret = TypedArray<GKSavedGame?>()
            if let savedGames = savedGames {
                for sg in savedGames {
                    ret.append(GKSavedGame(saved: sg))
                }
            }
            _ = callback.call(Variant(ret), mapError(error))
        }
    }

    @Callable
    func delete_saved_games(named: String, callback: Callable) {
        local.deleteSavedGames(withName: named) { error in
            _ = callback.call(mapError(nil))
        }
    }
}
