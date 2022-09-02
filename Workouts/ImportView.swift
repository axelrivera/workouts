//
//  ImportView.swift
//  Workouts
//
//  Created by Axel Rivera on 8/10/22.
//

import SwiftUI
import CoreData

struct ImportView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    var fileURL: URL?
    
    var body: some View {
        ImportContentView(fileURL: fileURL, manager: ImportManager(viewContext: viewContext))
    }
}

struct ImportContentView: View {
    @Environment(\.dismiss) private var dismiss
        
    @State var fileURL: URL?
    @StateObject var manager: ImportManager
    
    @State private var isProcessingAlertVisible = false
        
    var body: some View {
        NavigationView {
            Group {
                if manager.visibleScreen == .single {
                    SingleImportView(workout: manager.singleWorkout)
                        .environmentObject(manager)
                } else if manager.visibleScreen == .multiple {
                    MultipleImportView()
                        .environmentObject(manager)
                } else {
                    ImportEmptyView(state: manager.emptyState)
                        .edgesIgnoringSafeArea(.top)
                }
            }
            .onAppear(perform: requestWritingAuthorization)
            .interactiveDismissDisabled()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: dismissSheet) {
                        Text(ActionStrings.done)
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: add) {
                        Image(systemName: "plus")
                    }
                    .disabled(!manager.emptyState.isReady || manager.isProcessing)
                }
            }
            .fileImporter(
                isPresented: $manager.showDocumentPicker,
                allowedContentTypes: [.fitDocument],
                allowsMultipleSelection: true)
            { result in
                processFiles(result)
            }
            .alert(NSLocalizedString("Import in Progress", comment: "Alert title"), isPresented: $isProcessingAlertVisible) {
                Button(ActionStrings.ok, role: .cancel, action: {})
            } message: {
                Text(NSLocalizedString("Please wait until import process ends.", comment: "Alert message"))
            }

        }
    }
    
}

extension ImportContentView {
    
    func add() {
        guard manager.emptyState == .default else { return }
        
        manager.requestWritingAuthorization { success in
            DispatchQueue.main.async {
                if success {
                    AnalyticsManager.shared.capture(.addWorkoutFile)
                    self.manager.showDocumentPicker = true
                } else {
                    self.manager.emptyState = .notAvailable
                }
            }
        }
    }
    
    func requestWritingAuthorization() {
        manager.requestAuthorizationStatus { success in
            guard success else {
                Log.debug("request authorization failed")
                return
            }
            
            processURLIfNeeded()
        }
    }
    
    func dismissSheet() {
        if manager.isProcessing {
            isProcessingAlertVisible = true
        } else {
            Synchronizer.fetchRemoteData()
            dismiss()
        }
    }
    
    func processURLIfNeeded() {
        guard let url = fileURL else { return }
        self.fileURL = nil
        processFiles(.success([url]))
    }
    
    func processFiles(_ result: Result<[URL], Error>) {
        Task(priority: .userInitiated) {
            switch result {
            case .success(let urls):
                if urls.count > 1 {
                    DispatchQueue.main.async {
                        withAnimation {
                            manager.visibleScreen = .multiple
                            manager.isGeneratingWorkoutFiles = true
                        }
                    }
                }
                
                let documents = urls.map({ FitDocument(fileURL: $0 )})
                await self.manager.generateWorkouts(with: documents)
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.manager.isGeneratingWorkoutFiles = false
                    }
                }
            case .failure(let error):
                Log.debug("open document failed: \(error.localizedDescription)")
            }
        }
    }
    
}

struct ImportView_Previews: PreviewProvider {
    static var viewContext = WorkoutsProvider.preview.container.viewContext
    
    static var previews: some View {
        ImportView()
            .environment(\.managedObjectContext, viewContext)
    }
}
