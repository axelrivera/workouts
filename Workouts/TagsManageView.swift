//
//  TagsView.swift
//  Workouts
//
//  Created by Axel Rivera on 10/25/21.
//

import SwiftUI

struct TagsManageView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    var body: some View {
        TagsManageContentView(manager: TagManager(context: viewContext))
    }
}

struct TagsManageContentView: View {
    enum ActiveSheet: Hashable, Identifiable {
        case add, edit(tag: Tag)
        var id: Self { self }
    }
    
    enum ActiveAlert: Hashable, Identifiable {
        case delete(message: String, offsets: IndexSet)
        case error(message: String)
        var id: Self { self }
    }
        
    @StateObject var manager: TagManager
    
    @State var editMode = EditMode.inactive
    @State private var activeSheet: ActiveSheet?
    @State private var activeAlert: ActiveAlert?
    
    @State var selectedSegment = TagPickerSegment.active
        
    var body: some View {
        List {
            Section(header: header(), footer: editFooter()) {
                switch selectedSegment {
                case .active:
                    if editMode.isEditing && manager.tags.isEmpty {
                        Text(LabelStrings.noTags)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        activeTags()
                    }
                case .archived:
                    if manager.archived.isEmpty {
                        Text(LabelStrings.noArchivedTags)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        archivedTags()
                    }
                }
            }
            .textCase(nil)
        }
        .onAppear { manager.reloadData() }
        .listStyle(InsetGroupedListStyle())
        .overlay(emptyOverlay())
        .navigationTitle(LabelStrings.tags)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
               EditButton()
                    .disabled(selectedSegment == .archived)
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                
                Button(action: { activeSheet = .add }) {
                    Label(ActionStrings.newTag, systemImage: "plus.circle.fill")
                        .labelStyle(TitleAndIconLabelStyle())
                }
                .disabled(isNewButtonDisabled)
            }
        }
        .environment(\.editMode, $editMode)
        .sheet(item: $activeSheet, onDismiss: reload) { sheet in
            switch sheet {
            case .add:
                TagsAddView(viewModel: Tag.addViewModel(), source: .manage, isInsert: false)
                    .environmentObject(manager)
            case .edit(let tag):
                TagsAddView(viewModel: tag.editViewModel(), source: .manage, isInsert: false)
                    .environmentObject(manager)
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .delete(let message, let offsets):
                let deleteButton = Alert.Button.destructive(
                    Text(ActionStrings.delete),
                    action: { delete(at: offsets) }
                )
                
                return Alert(
                    title: Text(LabelStrings.confirmation),
                    message: Text(message),
                    primaryButton: deleteButton,
                    secondaryButton: Alert.Button.cancel()
                )
            case .error(let message):
                return Alert(
                    title: Text(TagStrings.errorTitle),
                    message: Text(message),
                    dismissButton: Alert.Button.default(Text(ActionStrings.ok))
                )
            }
        }
    }
    
    @ViewBuilder
    func activeTags() -> some View {
        ForEach(manager.tags, id: \.self) { tag in
            HStack {
                HStack {
                    GearImage(gearType: tag.gearType)
                        .foregroundColor(tag.color == nil ? .accentColor : Color(tag.color!))
                    Text(tag.name)
                }
                
                if editMode == .inactive {
                    Spacer()
                    Button(action: { activeSheet = .edit(tag: tag) }) {
                        Image(systemName: "info.circle")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onMove(perform: move)
        .onDelete(perform: editMode == .active ? delete : nil)
    }
    
    @ViewBuilder
    func archivedTags() -> some View {
        ForEach(manager.archived, id: \.self) { tag in
            HStack {
                HStack {
                    GearImage(gearType: tag.gearType)
                        .foregroundColor(tag.color == nil ? .accentColor : Color(tag.color!))
                    Text(tag.name)
                }
                
                Spacer()
                Button(action: { activeSheet = .edit(tag: tag) }) {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.borderless)
            }
        }
    }
    
    @ViewBuilder
    func header() -> some View {
        VStack(spacing: 20.0) {
            Picker(LabelStrings.tags, selection: $selectedSegment) {
                ForEach(TagPickerSegment.allCases, id: \.self) { segment in
                    Text(segment.title)
                }
            }
            .disabled(isManagingDisabled)
            .pickerStyle(SegmentedPickerStyle())
        }
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .padding([.top, .bottom], CGFloat(20.0))
    }
    
    @ViewBuilder
    func editFooter() -> some View {
        if editMode == .active {
            Text(NSLocalizedString("Deleted tags cannot be restored.", comment: "Tag error message"))
        }
    }
    
    @ViewBuilder
    func emptyOverlay() -> some View {
        if selectedSegment == .active && !editMode.isEditing && manager.tags.isEmpty {
            EmptyTagsView(displayType: .selector, onCreate: manager.reloadData)
        }
    }
    
}

// MARK: - Actions

extension TagsManageContentView {
    
    var isManagingDisabled: Bool {
        editMode == .active
    }
    
    var isNewButtonDisabled: Bool {
        if selectedSegment == .archived { return true }
        if editMode.isEditing { return true}
        return isManagingDisabled
    }
    
    func reload() {
        manager.reloadData()
        if selectedSegment == .archived && manager.archived.isEmpty {
            selectedSegment = .active
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        manager.tags.move(fromOffsets: source, toOffset: destination)
        manager.updatePositions()
    }
    
    func delete(at offsets: IndexSet) {
        do {
            try manager.deleteTags(atOffsets: offsets)
        } catch {
            activeAlert = .error(message: NSLocalizedString("Error deleting tag.", comment: "Tag error message"))
        }
        
    }
    
}

struct TagsManageView_Previews: PreviewProvider {
    static var viewContext = WorkoutsProvider.preview.container.viewContext
    
    static var previews: some View {
        NavigationView {
            TagsManageView()
        }
        .environment(\.managedObjectContext, viewContext)
    }
}
