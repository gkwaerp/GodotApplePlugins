//
//  GodotApplePlugins.swift
//  GodotApplePlugins
//
//  Created by Miguel de Icaza on 11/14/25.
//

import SwiftGodotRuntime

#initSwiftExtension(
    cdecl: "godot_apple_plugins_start",
    types: [
        AVAudioSession.self,
        GameCenterManager.self,
        GKAchievement.self,
        GKAchievementDescription.self,
        GKGameCenterViewController.self,
        GKLocalPlayer.self,
        GKLeaderboard.self,
        GKLeaderboardSet.self,
        GKMatch.self,
        GKMatchmakerViewController.self,
        GKMatchRequest.self,
        GKPlayer.self,
        GKSavedGame.self
    ],
    enums: [
        GKGameCenterViewController.State.self,
        GKLeaderboard.AppleLeaderboardType.self,
        GKLeaderboard.TimeScope.self,
        GKLeaderboard.PlayerScope.self,
        GKMatch.SendDataMode.self,
        GKMatchRequest.MatchType.self,
        AVAudioSession.SessionCategory.self,
    ])
