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
        case manage
        var id: Int { hashValue }
    }
    
    @StateObject var manager: TagsDisplayManager
    @State private var activeSheet: ActiveSheet?
    
    @State var selectedSegment = TagPickerSegments.active
                
    var body: some View {
        NavigationView {
            List {
                Section(header: header()) {
                    ForEach(manager.tags, id: \.id) { viewModel in
                        NavigationLink(destination: Text("Tags")) {
                            TagSummaryCell(viewModel: viewModel)
                                .padding([.top, .bottom], CGFloat(5.0))
                        }
                    }
                }
                .textCase(nil)
            }
            .onAppear(perform: { manager.reload() })
            .listStyle(PlainListStyle())
            .navigationTitle("Tags")
            .environment(\.defaultMinListHeaderHeight, 20.0)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Manage", action: { activeSheet = .manage })
                }
            }
            .sheet(item: $activeSheet, onDismiss: { manager.reload() }) { sheet in
                switch sheet {
                case .manage:
                    TagsManageView()
                }
            }
            
        }
    }
    
    @ViewBuilder
    func header() -> some View {
        Picker("Tags", selection: $selectedSegment) {
            ForEach(TagPickerSegments.allCases, id: \.self) { segment in
                Text(segment.title)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding([.top, .bottom], 5.0)
    }
    
}

struct TagsView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
        
    static var previews: some View {
        TagsView()
            .environment(\.managedObjectContext, viewContext)
            .preferredColorScheme(.dark)
    }
}
