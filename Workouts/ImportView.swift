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
    
    @State var activeSheet: ActiveSheet?
    @State var activeAlert: ActiveAlert?
    
    var body: some View {
        NavigationView {
            VStack {
                if importManager.workouts.isEmpty {
                    Spacer()
                    VStack(alignment: .center, spacing: 10.0) {
                        Image(systemName: "icloud.and.arrow.down")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        Text("Tap the + icon to import one or more workouts from iCloud. Only FIT files are supported.")
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .foregroundColor(.secondary)
                    Spacer()
                } else {
                    Form {
                        ForEach(importManager.workouts) { workout in
                            ImportRow(workout: workout)
                        }
                        .onDelete(perform: importManager.deleteWorkout)
                    }
                }
                
                RoundButton(text: "Import", action: processImports)
                    .padding()
                    .disabled(!importManager.canImport || importManager.isProcessingImports)
            }
            .navigationBarTitle("Import Workouts")
            .navigationBarItems(leading: dismissButton(), trailing: addButton())
            .sheet(item: $activeSheet) { item in
                switch item {
                case .document:
                    DocumentPicker(forOpeningContentTypes: [.fitDocument]) { urls in
                        importManager.processDocuments(at: urls)
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
        .disabled(importManager.isProcessingImports)
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
//        manager.loadSampleWorkouts()
        return manager
    }()
    
    static var previews: some View {
        ImportView(importManager: importManager)
    }
}
