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
        
    @Environment(\.presentationMode) var presentationMode
    @StateObject var manager: TagManager
    
    @State var editMode = EditMode.inactive
    @State private var activeSheet: ActiveSheet?
    @State private var activeAlert: ActiveAlert?
    
    @State var selectedSegment = TagPickerSegments.active
        
    var body: some View {
        NavigationView {
            List {
                Section(header: header(), footer: editFooter()) {
                    switch selectedSegment {
                    case .active:
                        if manager.tags.isEmpty {
                            Text("No Active Tags")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            activeTags()
                        }
                    case .archived:
                        if manager.archived.isEmpty {
                            Text("No Archived Tags")
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
            .navigationViewStyle(StackNavigationViewStyle())
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                   EditButton()
                        .disabled(selectedSegment == .archived)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: { presentationMode.wrappedValue.dismiss() })
                        .opacity(editMode.isEditing ? 0.0 : 1.0)
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    
                    Button(action: { activeSheet = .add }) {
                        Label("New Tag", systemImage: "plus.circle.fill")
                            .labelStyle(TitleAndIconLabelStyle())
                            .disabled(selectedSegment == .archived)
                    }
                    .disabled(editMode.isEditing)
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(item: $activeSheet, onDismiss: reload) { sheet in
                switch sheet {
                case .add:
                    TagsAddView(viewModel: Tag.addViewModel())
                        .environmentObject(manager)
                case .edit(let tag):
                    TagsAddView(viewModel: tag.editViewModel())
                        .environmentObject(manager)
                }
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .delete(let message, let offsets):
                    let deleteButton = Alert.Button.destructive(
                        Text("Delete"),
                        action: { delete(at: offsets) }
                    )
                    
                    return Alert(
                        title: Text("Confirmation"),
                        message: Text(message),
                        primaryButton: deleteButton,
                        secondaryButton: Alert.Button.cancel()
                    )
                case .error(let message):
                    return Alert(
                        title: Text("Tag Error"),
                        message: Text(message),
                        dismissButton: Alert.Button.default(Text("Ok"))
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    func activeTags() -> some View {
        ForEach(manager.tags, id: \.self) { tag in
            HStack {
                HStack {
                    gearImage(for: tag)
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
                    gearImage(for: tag)
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
        Picker("Tags", selection: $selectedSegment) {
            ForEach(TagPickerSegments.allCases, id: \.self) { segment in
                Text(segment.title)
            }
        }
        .disabled(editMode == .active)
        .pickerStyle(SegmentedPickerStyle())
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .padding([.top, .bottom], CGFloat(20.0))
    }
    
    @ViewBuilder
    func editFooter() -> some View {
        if editMode == .active {
            Text("Deleted tags cannot be restored.")
        }
    }
    
    @ViewBuilder
    func gearImage(for tag: Tag) -> some View {
        switch tag.gearType {
        case .bike:
            Image(systemName: "bicycle")
        case .shoes:
            Image(uiImage: UIImage(named: "shoe-prints-solid")!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22.0)
        case .none:
            Image(systemName: "tag")
        }
    }
    
}

// MARK: - Actions

extension TagsManageContentView {
    
    func reload() {
        manager.reloadData()
        if selectedSegment == .archived && manager.archived.isEmpty {
            selectedSegment = .active
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        manager.tags.move(fromOffsets: source, toOffset: destination)
    }
    
    func delete(at offsets: IndexSet) {
        do {
            try manager.deleteTags(atOffsets: offsets)
        } catch {
            activeAlert = .error(message: "Error deleting tag.")
        }
        
    }
    
}

struct TagsManageView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    
    static var previews: some View {
        TagsManageView()
            .environment(\.managedObjectContext, viewContext)
    }
}
