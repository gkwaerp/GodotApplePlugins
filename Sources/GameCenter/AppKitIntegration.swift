//
//  AppKitIntegration.swift
//  GodotApplePlugins
//
//  Created by Miguel de Icaza on 11/15/25.
//

#if canImport(AppKit)
import AppKit

@MainActor
func presentOnTop(_ vc: NSViewController) {
    guard let window = NSApp.keyWindow ?? NSApp.mainWindow else {
        // Fallback: frontmost window if needed
        NSApp.activate(ignoringOtherApps: true)
        return
    }

    window.contentViewController?.presentAsSheet(vc)
}

extension NSImage {
    func pngData() -> Data? {
        // Try via TIFF representation first (works for many NSImage sources)
        if let tiff = self.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let data = rep.representation(using: .png, properties: [:]) {
            return data
        }

        // Fallback: attempt via CGImage-backed rep
        var proposedRect = NSRect(origin: .zero, size: self.size)
        if let cgImage = self.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) {
            let rep = NSBitmapImageRep(cgImage: cgImage)
            return rep.representation(using: .png, properties: [:])
        }

        return nil
    }
}
#endif
