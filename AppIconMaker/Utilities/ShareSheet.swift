//
//  ShareSheet.swift
//  AppIconMaker
//
//  Created by App Icon Maker
//

import SwiftUI

#if os(iOS)
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var completion: (() -> Void)?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            completion?()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

#elseif os(macOS)
import AppKit

struct ShareSheet: NSViewRepresentable {
    let items: [Any]
    var completion: (() -> Void)?
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        DispatchQueue.main.async {
            guard let url = items.first as? URL else { return }
            
            let picker = NSSavePanel()
            picker.nameFieldStringValue = url.lastPathComponent
            picker.canCreateDirectories = true
            picker.begin { response in
                if response == .OK, let destinationURL = picker.url {
                    do {
                        // Copy the file/folder to the selected location
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }
                        try FileManager.default.copyItem(at: url, to: destinationURL)
                        completion?()
                    } catch {
                        print("Failed to save: \(error)")
                    }
                }
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // No update needed
    }
}

#endif
