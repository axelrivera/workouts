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
                Form {
                    if importManager.state == .processing {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }
                        .id(UUID())
                    } else {
                        ForEach(importManager.workouts) { workout in
                            ImportRow(workout: workout) {
                                importManager.processWorkout(workout)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .onAppear { importManager.requestWritingAuthorization { Log.debug("writing authorization succeeded: \($0)") } }
                
                if importManager.state.showEmptyView {
                    Color.systemBackground
                        .ignoresSafeArea()
                    ImportEmptyView(importState: importManager.state, addAction: { activeSheet = .document })
                }
            }
            .navigationTitle("Import Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: dismissButton(), trailing: addButton())
            .sheet(item: $activeSheet) { item in
                switch item {
                case .document:
                    DocumentPicker(forOpeningContentTypes: [.fitDocument, .zip]) { urls in
                        importManager.state = .processing
                        importManager.processDocuments(at: urls) {
                            importManager.state = urls.isEmpty ? .empty : .ok
                            Log.debug("finish processing documents")
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
    
    func addButton() -> some View {
        Button(action: { activeSheet = .document }) {
            Image(systemName: "plus")
        }
        .disabled(withAnimation { importManager.isAddImportDisabled })
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
