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
    
    enum ActiveCover: Identifiable {
        case settings
        var id: Int { hashValue }
    }
    
    enum ActiveAlert: Identifiable {
        case error
        var id: Int { hashValue }
    }
    
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var purchaseManager: IAPManager
    @StateObject var manager: TagsDisplayManager
    
    @State private var currentSegment = TagPickerSegment.active
    
    @State private var tags = [TagSummaryViewModel]()
    
    @State private var activeCover: ActiveCover?
    @State private var activeAlert: ActiveAlert?
    @State private var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(tags, id: \.id) { viewModel in
                        NavigationLink(destination: destination(for: viewModel)) {
                            SummaryCell(viewModel: viewModel, active: true)
                                .padding([.leading, .trailing])
                                .padding([.top, .bottom], CGFloat(10.0))
                        }
                        .contextMenu {
                            Button(action: { editTag(viewModel.id) }) {
                                Label(ActionStrings.edit, systemImage: "pencil")
                            }
                        }
                        .buttonStyle(WorkoutPlainButtonStyle())
                        Divider()
                    }
                }
            }
            .onAppear { reload() }
            .overlay(emptyView())
            .navigationTitle(NSLocalizedString("Tags", comment: "Screen title"))
            .onChange(of: currentSegment) { newValue in
                reload()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { activeCover = .settings }) {
                       Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker(LabelStrings.state, selection: $currentSegment.animation(.none)) {
                            ForEach(TagPickerSegment.allCases, id: \.self) { item in
                                Text(item.title).tag(item)
                            }
                        }
                    } label: {
                        Text(currentSegment.title)
                    }
                }
            }
            .sheet(item: $activeSheet, onDismiss: reload) { item in
                switch item {
                case .edit(let viewModel):
                    TagsAddView(viewModel: viewModel, source: .tags, isInsert: false)
                        .environmentObject(TagManager(context: viewContext))
                }
            }
            .fullScreenCover(item: $activeCover, onDismiss: reload) { item in
                switch item {
                case .settings:
                    SettingsView()
                        .environmentObject(purchaseManager)
                }
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .error:
                    return Alert(
                        title: Text(TagStrings.errorTitle),
                        message: Text(NSLocalizedString("Error processing action.", comment: "Alert message")),
                        dismissButton: Alert.Button.cancel(Text(ActionStrings.ok))
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    func emptyView() -> some View {
        if currentSegment == .active && tags.isEmpty {
            EmptyTagsView(displayType: .tags, onCreate: reload)
        } else if currentSegment == .archived && tags.isEmpty {
            Text(LabelStrings.noTags)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    func destination(for viewModel: TagSummaryViewModel) -> some View {
        StatsTimelineView(
            source: .tags,
            title: viewModel.title,
            subtitle: viewModel.gearType == .none ? LabelStrings.tag : viewModel.gearType.title,
            sport: viewModel.gearType.displaySport,
            interval: manager.dataProvider.dateIntervalForActiveWorkouts(),
            timeframe: .year,
            identifiers: manager.workoutTagProvider.workoutIdentifiers(forTag: viewModel.id)
        )
        .onAppear { AnalyticsManager.shared.logPage(.tagMetrics) }
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
    static var viewContext = WorkoutsProvider.preview.container.viewContext
    static var purchaseManager = IAPManagerPreview.manager(isActive: true)
        
    static var previews: some View {
        TagsView()
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(purchaseManager)
            .preferredColorScheme(.dark)
    }
}
