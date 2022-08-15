//
//  MultipleImportView.swift
//  Workouts
//
//  Created by Axel Rivera on 8/10/22.
//

import SwiftUI

struct MultipleImportView: View {
    @EnvironmentObject var manager: ImportManager
    
    func singleImportView(for workout: WorkoutImport) -> some View {
        SingleImportView(workout: workout)
            .environmentObject(manager)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(manager.workouts, id: \.id) { workout in
                    NavigationLink(destination: singleImportView(for: workout)) {
                        ImportRow(workout: workout)
                    }
                }
                .onDelete(perform: manager.delete)
            }
            .listStyle(PlainListStyle())
            .overlay(content: hudOverlay)
            
            bottomBar()
                .disabled(manager.isProcessing)
        }
        .navigationTitle("Import Workouts")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    func hudOverlay() -> some View {
        if manager.isGeneratingWorkoutFiles {
            HUDView()
        }
    }
    
    @ViewBuilder
    func bottomBar() -> some View {
        HStack {
            Button(action: process) {
                Text("Import All")
                    .padding(CGFloat(10))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
            
            Button(action: manager.discardAll) {
                Text("Discard All")
                    .padding(CGFloat(10))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding([.leading, .trailing])
        .padding([.top, .bottom], CGFloat(10))
    }
    
}

extension MultipleImportView {
    
    func process() {
        Task(priority:.userInitiated) {
            await manager.processWorkouts()
        }
    }
    
}

struct MultipleImportView_Previews: PreviewProvider {
    static var viewContext = WorkoutsProvider.preview.container.viewContext
    static var manager = ImportManager(viewContext: viewContext)
    
    static var previews: some View {
        NavigationView {
            MultipleImportView()
                .environmentObject(manager)
        }
    }
}
