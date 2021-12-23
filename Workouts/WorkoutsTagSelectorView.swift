//
//  WorkoutsTagSelectorView.swift
//  Workouts
//
//  Created by Axel Rivera on 11/22/21.
//

import SwiftUI
import CoreData

struct WorkoutsTagSelectorView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    var body: some View {
        WorkoutsTagSelectorContent(manager: WorkoutsTagSelectorManager(context: viewContext))
    }
}

struct WorkoutsTagSelectorContent: View {
    enum ActiveSheet: Identifiable {
        case add
        var id: Int { hashValue }
    }
    
    enum ActiveAlert: Hashable, Identifiable {
        case error(message: String)
        var id: Self { self }
    }
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
    
    @StateObject var manager: WorkoutsTagSelectorManager
    
    @State private var activeSheet: ActiveSheet?
    @State private var activeAlert: ActiveAlert?
    
    var body: some View {
        NavigationView {
            TagSelector(
                tags: $manager.tags,
                selectedTags: $manager.selectedTags,
                defaultAction: manager.reload) { tag in
                do {
                    try manager.toggle(tag: tag)
                } catch {
                    activeAlert = .error(message: "Unable to update tag \(tag.name).")
                }
            }
            .onAppear { manager.reload() }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { presentationMode.wrappedValue.dismiss() })
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    
                    Button(action: { activeSheet = .add }) {
                        Label("New Tag", systemImage: "plus.circle.fill")
                            .labelStyle(TitleAndIconLabelStyle())
                    }
                }
            }
            .sheet(item: $activeSheet, onDismiss: reload) { item in
                switch item {
                case .add:
                    TagsAddView(viewModel: Tag.addViewModel(), isInsert: true)
                        .environmentObject(TagManager(context: viewContext))
                }
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .error(let message):
                    return Alert(
                        title: Text("Update Error"),
                        message: Text(message),
                        dismissButton: Alert.Button.default(Text("Ok"))
                    )
                }
            }
        }
    }
}

extension WorkoutsTagSelectorContent {
    
    func save() {
        let userInfo = [Notification.tagsKey: manager.selectedIdentifiers]
        NotificationCenter.default.post(name: .addTagsToAll, object: nil, userInfo: userInfo)
        presentationMode.wrappedValue.dismiss()
    }
    
    func reload() {
        withAnimation {
            manager.reload()
        }
    }
    
}

struct WorkoutsTagSelectorView_Previews: PreviewProvider {
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    @State static var tags = StorageProvider.previewTags(in: viewContext)
    
    static var previews: some View {
        WorkoutsTagSelectorView()
            .environment(\.managedObjectContext, viewContext)
    }
}

// MARK: - Manager

final class WorkoutsTagSelectorManager: ObservableObject {
    @Published var tags = [Tag]()
    @Published var selectedTags = Set<Tag>()
    
    let context: NSManagedObjectContext
    private let provider: TagProvider
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.provider = TagProvider(context: context)
    }
    
}

// MARK: Methods

extension WorkoutsTagSelectorManager {
    
    var selectedIdentifiers: [UUID] { selectedTags.map({ $0.uuid }) }
    
    func reload() {
        tags = provider.activeTags(sport: nil)
    }
    
    func isSelected(tag: Tag) -> Bool {
        selectedTags.contains(tag)
    }
    
    func toggle(tag: Tag) throws {
        if isSelected(tag: tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
}
