//
//  TagsAddView.swift
//  Workouts
//
//  Created by Axel Rivera on 10/25/21.
//

import SwiftUI

struct TagsAddView: View {
    enum ConfirmationType: Hashable, Identifiable {
        case archive(name: String)
        case restore(name: String)
        case delete(name: String)
        
        var id: Self { self }
        
        var message: String {
            switch self {
            case .archive(let name):
                return "Do you want to archive \(name)? Archived tags will not be available for selection in workouts."
            case .restore(let name):
                return "Do you want to restore \(name)?"
            case .delete(let name):
                return "Do you want to delete \(name)? Deleted tags cannot be restored."
            }
        }
        
        func alertButton(action: @escaping () -> Void) -> Alert.Button {
            switch self {
            case .delete:
                return Alert.Button.destructive(Text("Delete"), action: action)
            default:
                return Alert.Button.default(Text("Continue"), action: action)
            }
        }
    }
    
    enum ActiveAlert: Hashable, Identifiable {
        case error(message: String)
        case confirmation(confirmationType: ConfirmationType)
        var id: Self { self }
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var tagManager: TagManager
    @StateObject var viewModel: TagEditViewModel
    @State private var activeAlert: ActiveAlert?
    
    var isDisabled: Bool {
        viewModel.isArchived
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0.0) {
                Form {
                    Section {
                        TextField("Name", text: $viewModel.name, prompt: Text("Tag Name"))
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .foregroundColor(isDisabled ? .secondary : viewModel.color)
                            .autocapitalization(.words)
                    }
                    .disabled(isDisabled)
                    
                    if !isDisabled {
                        Section {
                            WorkoutColorPicker(selectedColor: $viewModel.color) { color in
                                
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding([.top, .bottom], CGFloat(10.0))
                        }
                    }
                    
                    Section(header: Text("Options"), footer: gearFooter()) {
                        if viewModel.availableGearTypes.isPresent {
                            Picker("Gear Type", selection: $viewModel.gearType) {
                                ForEach(viewModel.availableGearTypes, id: \.self) { gear in
                                    Text(gear.rawValue.capitalized)
                                }
                            }
                        }
                        
                        Toggle("Default", isOn: $viewModel.isDefault)
                            .foregroundColor(isDisabled ? .secondary : .primary)
                    }
                    .disabled(viewModel.isArchived)
                }
                
                if viewModel.mode == .edit {
                    HStack {
                        if viewModel.isArchived {
                            Button(action: toggleRestore) {
                                Label("Restore", systemImage: "gobackward")
                                    .frame(maxWidth: .infinity)
                                    .padding(.all, CGFloat(5.0))
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button(action: toggleArchive) {
                                Label("Archive", systemImage: "archivebox")
                                    .frame(maxWidth: .infinity)
                                    .padding(.all, CGFloat(5.0))
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Button(action: toggleDelete) {
                            Label("Delete", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding(.all, CGFloat(5.0))
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                    .padding()
                }
            }
            .interactiveDismissDisabled()
            .navigationTitle(viewModel.mode == .add ? "New Tag" : "Edit Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { presentationMode.wrappedValue.dismiss() })
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: addTag)
                        .disabled(viewModel.isArchived)
                }
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .confirmation(let confirmationType):
                    return Alert(
                        title: Text("Confirmation"),
                        message: Text(confirmationType.message),
                        primaryButton: confirmationType.alertButton(action: { confirmationAction(confirmationType) }),
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
    func gearFooter() -> some View {
        switch viewModel.gearType {
        case .none:
            Text("Default tags will be applied to all new workouts.")
        default:
            Text("Default tags will be applied to new workouts based on gear type.")
        }
    }
}

extension TagsAddView {
    
    func addTag() {
        do {
            try tagManager.addTag(viewModel: viewModel)
            presentationMode.wrappedValue.dismiss()
        } catch {
            activeAlert = .error(message: error.localizedDescription)
        }
    }
    
    func toggleArchive() {
        activeAlert = .confirmation(confirmationType: .archive(name: viewModel.name))
    }
    
    func toggleRestore() {
        activeAlert = .confirmation(confirmationType: .restore(name: viewModel.name))
    }
    
    func toggleDelete() {
        activeAlert = .confirmation(confirmationType: .delete(name: viewModel.name))
    }
    
    func confirmationAction(_ confirmation: ConfirmationType) {
        switch confirmation {
        case .archive:
            archiveTag()
        case .restore:
            restoreTag()
        case .delete:
            deleteTag()
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    func archiveTag() {
        do {
            try tagManager.archiveTag(for: viewModel.uuid)
        } catch {
            activeAlert = .error(message: "Unable to archive tag.")
        }
    }
    
    func restoreTag() {
        do {
            try tagManager.restoreTag(for: viewModel.uuid)
        } catch {
            activeAlert = .error(message: "Unable to restore tag.")
        }
    }
    
    func deleteTag() {
        do {
            try tagManager.deleteTag(for: viewModel.uuid)
        } catch {
            
        }
    }
    
}

struct TagsAddView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var tagManager = TagManager(context: viewContext)
    
    static var viewModel: TagEditViewModel = {
        var model = TagEditViewModel(uuid: UUID(), mode: .edit)
        model.isArchived = false
        return model
    }()
    
    static var previews: some View {
        TagsAddView(viewModel: viewModel)
            .environmentObject(tagManager)
            .preferredColorScheme(.light)
    }
}
