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
    enum ActiveSheet: Hashable, Identifiable {
        case edit(viewModel: TagEditViewModel)
        var id: Self { self }
    }
    
    enum ActiveAlert: Identifiable {
        case error
        var id: Int { hashValue }
    }
    
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var purchaseManager: IAPManager
    @StateObject var manager: TagsDisplayManager
    
    @State private var currentSegment = TagPickerSegment.active {
        didSet {
            reload()
        }
    }
    
    @State private var tags = [TagSummaryViewModel]()
    
    @State private var activeSheet: ActiveSheet?
    @State private var activeAlert: ActiveAlert?
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(tags, id: \.id) { viewModel in
                NavigationLink(destination: destination(for: viewModel)) {
                    SummaryCell(viewModel: viewModel, active: true)
                        .padding([.leading, .trailing])
                        .padding([.top, .bottom], CGFloat(10.0))
                }
                .contextMenu {
                    Button(action: { editTag(viewModel.id) }) {
                        Label("Edit", systemImage: "pencil")
                    }
                }
                .buttonStyle(WorkoutPlainButtonStyle())
                Divider()
            }
        }
        .onAppear { reload() }
        .overlay(emptyView())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(TagPickerSegment.allCases) { segment in
                        Button(action: { currentSegment = segment }) {
                            Text(segment.title)
                            if currentSegment == segment {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    Text(currentSegment.title)
                }
            }
        }
        .sheet(item: $activeSheet, onDismiss: { reload() }) { item in
            switch item {
            case .edit(let viewModel):
                TagsAddView(viewModel: viewModel, isInsert: false)
                    .environmentObject(TagManager(context: viewContext))
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .error:
                return Alert(
                    title: Text("Tag Error"),
                    message: Text("Error processing action."),
                    dismissButton: Alert.Button.cancel(Text("Ok"))
                )
            }
        }
    }
    
    @ViewBuilder
    func emptyView() -> some View {
        if tags.isEmpty {
            EmptyTagsView(displayType: .tags, onCreate: { reload() })
        }
    }
    
    @ViewBuilder
    func destination(for viewModel: TagSummaryViewModel) -> some View {
        StatsTimelineView(
            title: viewModel.title,
            subtitle: viewModel.gearType == .none ? "Tag" : viewModel.gearType.rawValue.capitalized,
            sport: nil,
            interval: manager.dataProvider.dateIntervalForActiveWorkouts(),
            timeframe: .year,
            identifiers: manager.workoutTagProvider.workoutIdentifiers(forTag: viewModel.id)
        )
    }
    
}

extension TagsContentView {
    
    func reload() {
        let tags = manager.tags(forSegment: currentSegment)
        self.tags = tags
    }
    
    func editTag(_ tag: UUID) {
        do {
            let viewModel = try manager.viewModel(forTag: tag)
            activeSheet = .edit(viewModel: viewModel)
        } catch {
            activeAlert = .error
        }
    }
    
    func archive(tag uuid: UUID) {
        do {
            try manager.archiveTag(for: uuid)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.linear) {
                    reload()
                }
            }
        } catch {
            activeAlert = .error
        }
    }
    
    func restore(tag uuid: UUID) {
        do {
            try manager.restoreTag(for: uuid)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.linear) {
                    reload()
                }
            }
        } catch {
            activeAlert = .error
        }
    }
    
}

struct TagsView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var purchaseManager = IAPManagerPreview.manager(isActive: true)
        
    static var previews: some View {
        NavigationView {
            ScrollView {
                TagsView()
            }
            .navigationTitle("Tags")
        }
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(purchaseManager)
        .preferredColorScheme(.dark)
    }
}
