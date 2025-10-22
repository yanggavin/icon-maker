//
//  ExportView.swift
//  AppIconMaker
//
//  Created by App Icon Maker
//

import SwiftUI

struct ExportView: View {
    let processedImage: UIImage
    
    @StateObject private var viewModel = ExportViewModel()
    @State private var showShareSheet = false
    @State private var showErrorAlert = false
    @Environment(\.dismiss) private var dismiss
    
    private var progressMessage: String {
        switch viewModel.progress {
        case 0..<0.3:
            return "Preparing export..."
        case 0.3..<0.6:
            return "Generating icons..."
        case 0.6..<0.9:
            return "Creating icon set..."
        default:
            return "Finalizing..."
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Platform Selection Section
                Section {
                    ForEach([Platform.iOS, Platform.iPadOS, Platform.macOS], id: \.self) { platform in
                        Toggle(isOn: Binding(
                            get: { viewModel.selectedPlatforms.contains(platform) },
                            set: { isSelected in
                                HapticFeedback.selection()
                                if isSelected {
                                    viewModel.selectedPlatforms.insert(platform)
                                } else {
                                    viewModel.selectedPlatforms.remove(platform)
                                }
                            }
                        )) {
                            HStack(spacing: 12) {
                                platformIcon(for: platform)
                                    #if os(macOS)
                                    .font(.title3)
                                    #endif
                                Text(platform.rawValue)
                                    #if os(macOS)
                                    .font(.body)
                                    #endif
                            }
                        }
                        .accessibilityLabel("\(platform.rawValue) Platform")
                        .accessibilityHint("Include \(platform.rawValue) icon sizes in export")
                    }
                } header: {
                    Text("Platforms")
                } footer: {
                    Text("Select the platforms you want to generate icons for")
                }
                
                // Export Format Section
                Section {
                    Picker("Format", selection: $viewModel.exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Export Format")
                    .accessibilityHint("Choose to export as a folder or ZIP archive")
                } header: {
                    Text("Export Format")
                } footer: {
                    Text(viewModel.exportFormat == .zip ? 
                         "Export as a ZIP archive for easy sharing" : 
                         "Export as a folder ready to drag into Xcode")
                }
                
                // Export Button Section
                Section {
                    Button(action: {
                        HapticFeedback.medium()
                        Task {
                            await performExport()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(viewModel.isExporting ? "Exporting..." : "Export Icons")
                                .fontWeight(.semibold)
                                #if os(macOS)
                                .font(.title3)
                                #endif
                            Spacer()
                        }
                        #if os(macOS)
                        .padding(.vertical, 8)
                        #endif
                    }
                    .disabled(viewModel.selectedPlatforms.isEmpty || viewModel.isExporting)
                    .accessibilityLabel(viewModel.isExporting ? "Exporting Icons" : "Export Icons")
                    .accessibilityHint("Generates and exports your icon set as an AppIcon.appiconset bundle")
                    
                    if viewModel.isExporting {
                        VStack(spacing: 8) {
                            ProgressView(value: viewModel.progress) {
                                Text("Progress")
                            } currentValueLabel: {
                                Text("\(Int(viewModel.progress * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            Text(progressMessage)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .navigationTitle("Export Icons")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isExporting)
                }
            }
            #if os(macOS)
            .frame(minWidth: 500, minHeight: 400)
            #endif
            .sheet(isPresented: $showShareSheet) {
                if let url = viewModel.exportedURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Export Failed", isPresented: $showErrorAlert) {
                Button("Retry") {
                    Task {
                        await performExport()
                    }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private func performExport() async {
        viewModel.isExporting = true
        viewModel.errorMessage = nil
        
        do {
            // Generate icons
            let iconSet = await viewModel.generateIcons(from: processedImage)
            
            // Export icon set
            let exportedURL = try await viewModel.exportIconSet(iconSet)
            
            viewModel.exportedURL = exportedURL
            viewModel.isExporting = false
            
            // Success feedback
            HapticFeedback.success()
            
            // Show share sheet
            showShareSheet = true
            
        } catch {
            viewModel.isExporting = false
            viewModel.errorMessage = error.localizedDescription
            HapticFeedback.error()
            showErrorAlert = true
        }
    }
    
    @ViewBuilder
    private func platformIcon(for platform: Platform) -> some View {
        switch platform {
        case .iOS:
            Image(systemName: "iphone")
        case .iPadOS:
            Image(systemName: "ipad")
        case .macOS:
            Image(systemName: "laptopcomputer")
        case .all:
            Image(systemName: "square.grid.2x2")
        }
    }
}
