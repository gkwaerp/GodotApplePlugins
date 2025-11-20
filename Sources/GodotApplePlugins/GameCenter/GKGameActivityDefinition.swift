//
//  GKGameActivityDefinition.swift
//  GodotApplePlugins
//
//  Created by Miguel de Icaza on 11/20/25.
//


@preconcurrency import SwiftGodotRuntime
import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
import GameKit

@available(iOS 26.0, macOS 26.0, *)
@Godot
class GKGameActivityDefinition: RefCounted, @unchecked Sendable {
    var definition: GameKit.GKGameActivityDefinition?

    @Export var title: String { definition?.title ?? ""}

    @Export var details: String { definition?.details ?? "" }

    @Export var defaultProperties: TypedDictionary<String,String> {
        get {
            return TypedDictionary<String,String>()
        }
    }
}
