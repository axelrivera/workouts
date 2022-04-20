//
//  ImportView.swift
//  Workouts
//
//  Created by Axel Rivera on 1/30/21.
//

import SwiftUI
import FitFileParser

struct ImportView: View {
    enum ActiveAlert: Identifiable {
        case dismiss
        var id: Int { hashValue }
    }
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject var importManager: ImportManager = ImportManager()
    var openURL: URL? = nil
    
    @State private var isProcessingDocuments = false
    
    @State private var activeAlert: ActiveAlert?
    @State private var shouldFetchWritePermission = false
    @State private var showDocumentPicker = false
        
    var body: some View {
        NavigationView {
            VStack {
                List(importManager.workouts, id: \.id) { workout in
                    ImportRow(workout: workout) {
                        AnalyticsManager.shared.capture(.importedWorkout)
                        importManager.processWorkout(workout)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listStyle(PlainListStyle())
                .modifier(ImportEmptyModifier(importState: importManager.state))
                
                Spacer()
                
                RoundButton(text: "Add FIT Files", action: addAction)
                    .disabled(importManager.isImportDisabled)
                    .padding()
            }
            .onAppear {
                requestWritingAuthorizationIfNeeded(onAppear: true)
                
            }
            .navigationTitle("Import Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: dismissAction) {
                        Text("Done")
                    }
                }
            }
            .fileImporter(isPresented: $showDocumentPicker, allowedContentTypes: [.fitDocument], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    importManager.state = .processing
                    
                    let documents = urls.map({ FitDocument(fileURL: $0) })
                    importManager.processDocuments(at: documents) {
                        importManager.state = urls.isEmpty ? .empty : .ok
                    }
                case .failure(let error):
                    Log.debug("failed to show document importer: \(error.localizedDescription)")
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
                    //activeSheet = .document
                    AnalyticsManager.shared.capture(.addWorkoutFile)
                    showDocumentPicker = true
                } else {
                    importManager.state = .notAuthorized
                }
            }
        }
    }
    
    func requestWritingAuthorizationIfNeeded(onAppear: Bool = false) {
        importManager.requestAuthorizationStatus { success in
            guard success else {
                Log.debug("request authorization failed")
                return
            }
            
            if let url = openURL {
                let document = FitDocument(fileURL: url)
                
                DispatchQueue.main.async {
                    importManager.state = .processing
                    importManager.processDocuments(at: [document]) {
                        importManager.state = .ok
                    }
                }
            }
        }
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
        
    static var previews: some View {
        ImportView(importManager: importManager)
    }
}
