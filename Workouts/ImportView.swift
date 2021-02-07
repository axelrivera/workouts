//
//  ImportView.swift
//  Workouts
//
//  Created by Axel Rivera on 1/30/21.
//

import SwiftUI

struct ImportView: View {
    enum ActiveSheet: Identifiable {
        case document
        var id: Int { hashValue }
    }
    
    enum ActiveAlert: Identifiable {
        case dismiss
        var id: Int { hashValue }
    }
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject var importManager: ImportManager = ImportManager()
    @State var isProcessingDocuments = false
    
    @State var activeSheet: ActiveSheet?
    @State var activeAlert: ActiveAlert?
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Form {
                        ForEach(importManager.workouts) { workout in
                            ImportRow(workout: workout)
                        }
                        .onDelete(perform: importManager.deleteWorkout)
                    }
                    .onAppear {
                        importManager.requestWritingAuthorization { (success) in
                            Log.debug("writing authorization succeeded: \(success)")
                        }
                    }
                    RoundButton(text: "Import", action: processImports)
                        .padding()
                        .disabled(importManager.isImportDisabled)
                }
                
                if isProcessingDocuments {
                    Color.systemBackground
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20.0) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Processing Files")
                    }
                } else if importManager.state != .ok {
                    Color.systemBackground
                        .ignoresSafeArea()
                    ImportEmptyView(importState: importManager.state)
                }
            }
            .navigationBarTitle("Import Workouts")
            .navigationBarItems(leading: dismissButton(), trailing: addButton())
            .sheet(item: $activeSheet) { item in
                switch item {
                case .document:
                    DocumentPicker(forOpeningContentTypes: [.fitDocument]) { urls in
                        Log.debug("processing documents")
                        
                        isProcessingDocuments = true
                        importManager.processDocuments(at: urls) {
                            Log.debug("finish processing documents")
                            isProcessingDocuments = false
                        }
                    }
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
    
    func processImports() {
        importManager.importWorkouts {
            Log.debug("finished importing workouts")
        }
    }
    
    func addButton() -> some View {
        Button(action: { activeSheet = .document }) {
            Image(systemName: "plus")
        }
        .disabled(importManager.isAddImportDisabled)
    }
    
    func dismissButton() -> some View {
        Button(action: { dismissAction(skipConfirmation: false) }) {
            Text("Done")
        }
    }
    
    func dismissAction(skipConfirmation: Bool) {
        if importManager.isProcessingImports {
            activeAlert = .dismiss
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    func formHeader() -> some View {
        HStack {
            Text("Files")
            Spacer()
            Button(action: {}) {
                Text("Select All")
            }
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
