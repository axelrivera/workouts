//
//  TagsView.swift
//  Workouts
//
//  Created by Axel Rivera on 10/30/21.
//

import SwiftUI
import CoreData

struct TagsView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    var body: some View {
        TagsContentView(manager: TagsDisplayManager(context: viewContext))
    }
}

struct TagsContentView: View {
    enum ActiveSheet: Identifiable {
        case settings
        var id: Int { hashValue }
    }
    
    @EnvironmentObject var purchaseManager: IAPManager
    @StateObject var manager: TagsDisplayManager
    @State private var activeSheet: ActiveSheet?
                
    var body: some View {
        NavigationView {
            List {
                Section(header: header()) {
                    ForEach(manager.tags, id: \.id) { viewModel in
                        NavigationLink(destination: TagWorkoutsView(viewModel: viewModel)) {
                            TagSummaryCell(viewModel: viewModel)
                                .padding([.top, .bottom], CGFloat(5.0))
                        }
                    }
                }
                .textCase(nil)
            }
            .transition(.move(edge: .top))
            .onAppear(perform: { manager.reload() })
            .listStyle(PlainListStyle())
            .navigationTitle("Tags")
            .environment(\.defaultMinListHeaderHeight, 20.0)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { activeSheet = .settings }) {
                       Image(systemName: "gearshape")
                    }
                }
            }
            .fullScreenCover(item: $activeSheet, onDismiss: { manager.reload() }) { item in
                switch item {
                case .settings:
                    SettingsView()
                        .environmentObject(purchaseManager)
                }
            }
        }
    }
    
    @ViewBuilder
    func header() -> some View {
        if manager.showPicker {
            Picker("Tags", selection: $manager.currentSegment) {
                ForEach(TagPickerSegments.allCases, id: \.self) { segment in
                    Text(segment.title)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding([.top, .bottom], 5.0)
        }
    }
    
}

struct TagsView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var purchaseManager = IAPManagerPreview.manager(isActive: true)
        
    static var previews: some View {
        TagsView()
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(purchaseManager)
            .preferredColorScheme(.dark)
    }
}
