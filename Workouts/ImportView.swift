//
//  ImportView.swift
//  Workouts
//
//  Created by Axel Rivera on 1/30/21.
//

import SwiftUI

struct ImportView: View {
    enum ActiveSheet: Identifiable {
        case document, paywall
        var id: Int { hashValue }
    }
    
    enum ActiveAlert: Identifiable {
        case dismiss
        var id: Int { hashValue }
    }
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var purchaseManager: IAPManager
    @StateObject var importManager: ImportManager = ImportManager()
    
    @State private var isProcessingDocuments = false
    
    @State private var activeSheet: ActiveSheet?
    @State private var activeAlert: ActiveAlert?
    @State private var shouldFetchWritePermission = false
    
    var body: some View {
        NavigationView {
            VStack {
                List(importManager.workouts) { workout in
                    ImportRow(workout: workout) {
                        importManager.processWorkout(workout)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listStyle(InsetGroupedListStyle())
                .modifier(ImportEmptyModifier(importState: importManager.state, isActive: purchaseManager.isActive))
                
                Spacer()
                
                if purchaseManager.isActive {
                    RoundButton(text: "Add FIT Files", action: addAction)
                        .disabled(importManager.isImportDisabled)
                        .padding()
                } else {
                    VStack(spacing: 20.0) {
                        Text("Importing FIT Files requires\nBetter Workouts Pro")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        PaywallButton(action: paywallAction)
                    }
                    .padding()
                }
            }
            .onAppear { requestWritingAuthorizationIfNeeded() }
            .navigationTitle("Import Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: dismissAction) {
                        Text("Done")
                    }
                }
            }
            .sheet(item: $activeSheet, onDismiss: onSheetDismiss) { item in
                switch item {
                case .document:
                    DocumentPicker(forOpeningContentTypes: [.fitDocument, .zip]) { urls in
                        importManager.state = .processing
                        importManager.processDocuments(at: urls) {
                            importManager.state = urls.isEmpty ? .empty : .ok
                        }
                    }
                case .paywall:
                    PaywallView()
                        .environmentObject(purchaseManager)
                }
            }
            .alert(item: $activeAlert) { item in
                switch item {
                case .dismiss:
                    return Alert(
                        title:  Text("Import In Progress"),
                        message: Text("Please wait until import finishes."),
                        dismissButton: .default(Text("Ok"))
                    )
                }
            }
        }
    }
}

private extension ImportView {
    
    func addAction() {
        if importManager.state == .processing { return }
        
        importManager.requestWritingAuthorization { success in
            DispatchQueue.main.async {
                if success {
                    activeSheet = .document
                } else {
                    importManager.state = .notAuthorized
                }
            }
        }
    }
    
    func paywallAction() {
        shouldFetchWritePermission = true
        activeSheet = .paywall
    }
    
    func requestWritingAuthorizationIfNeeded() {
        guard purchaseManager.isActive else { return }
        importManager.requestWritingAuthorization { Log.debug("writing authorization succeeded: \($0)") }
    }
    
    func onSheetDismiss() {
        if shouldFetchWritePermission {
            requestWritingAuthorizationIfNeeded()
        }
        shouldFetchWritePermission = false
    }
    
    func dismissAction() {
        if importManager.isProcessingImports {
            activeAlert = .dismiss
        } else {
            NotificationCenter.default.post(name: .shouldFetchRemoteData, object: nil)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
}

struct ImportView_Previews: PreviewProvider {
    static let importManager: ImportManager = {
        let manager = ImportManager()
        manager.state = .ok
        manager.loadSampleWorkouts()
        return manager
    }()
    
    static let purchaseManager = IAPManager.preview(isActive: false)
    
    static var previews: some View {
        ImportView(importManager: importManager)
            .environmentObject(purchaseManager)
    }
}
