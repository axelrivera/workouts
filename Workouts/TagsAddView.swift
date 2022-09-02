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
                let string = NSLocalizedString("Do you want to archive %@? Archived tags will not be available for selection in workouts.", comment: "Tag confirmation")
                return String(format: string, name)
            case .restore(let name):
                let string = NSLocalizedString("Do you want to restore %@?", comment: "Tag confirmation")
                return String(format: string, name)
            case .delete(let name):
                let string = NSLocalizedString("Do you want to delete %@? Deleted tags cannot be restored.", comment: "Tag confirmation")
                return String(format: string, name)
            }
        }
        
        func alertButton(action: @escaping () -> Void) -> Alert.Button {
            switch self {
            case .delete:
                return Alert.Button.destructive(Text(ActionStrings.delete), action: action)
            default:
                return Alert.Button.default(Text(ActionStrings.continue), action: action)
            }
        }
    }
    
    enum ActiveAlert: Hashable, Identifiable {
        case error(message: String)
        case confirmation(confirmationType: ConfirmationType)
        var id: Self { self }
    }
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
    
    @EnvironmentObject private var tagManager: TagManager
    
    @State private var activeAlert: ActiveAlert?
    
    @StateObject var viewModel: TagEditViewModel
    var source: AnalyticsManager.TagSource
    var isInsert: Bool
    
    var isDisabled: Bool {
        viewModel.isArchived
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0.0) {
                Form {
                    Section {
                        TextField(LabelStrings.name, text: $viewModel.name, prompt: Text(LabelStrings.tagName))
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .foregroundColor(isDisabled ? .secondary : viewModel.color)
                            .autocapitalization(.words)
                    }
                    .disabled(isDisabled)
                    
                    if !isDisabled {
                        Section {
                            WorkoutColorPicker(colors: Color.tagColors, selectedColor: $viewModel.color) { color in
                                
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding([.top, .bottom], CGFloat(10.0))
                        }
                    }
                    
                    if viewModel.mode == .add {
                        if viewModel.availableGearTypes.isPresent {
                            Section(footer: Text(NSLocalizedString("Gear Type cannot be edited later.", comment: "Gear edit message"))) {
                                Picker(LabelStrings.gearType, selection: $viewModel.gearType) {
                                    ForEach(viewModel.availableGearTypes, id: \.self) { gear in
                                        Text(gear.title)
                                    }
                                }
                            }
                        }
                    } else {
                        Section {
                            HStack {
                                Text(LabelStrings.gearType)
                                Spacer()
                                Text(viewModel.gearType.title)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section(footer: defaultValueFooter()) {
                        Toggle(LabelStrings.default, isOn: $viewModel.isDefault)
                            .foregroundColor(isDisabled ? .secondary : .primary)
                    }
                    .disabled(viewModel.isArchived)
                }
                
                if viewModel.mode == .edit {
                    VStack {
                        HStack {
                            if viewModel.isArchived {
                                Button(action: toggleRestore) {
                                    Label(ActionStrings.restore, systemImage: "arrow.uturn.backward")
                                        .frame(maxWidth: .infinity)
                                        .padding(.all, CGFloat(5.0))
                                }
                                .buttonStyle(.bordered)
                            } else {
                                Button(action: toggleArchive) {
                                    Label(ActionStrings.archive, systemImage: "archivebox")
                                        .frame(maxWidth: .infinity)
                                        .padding(.all, CGFloat(5.0))
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            Button(action: toggleDelete) {
                                Label(ActionStrings.delete, systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                                    .padding(.all, CGFloat(5.0))
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                    .padding()
                }
            }
            .interactiveDismissDisabled()
            .navigationTitle(viewModel.mode == .add ? ActionStrings.newTag : ActionStrings.editTag)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(ActionStrings.cancel, action: { presentationMode.wrappedValue.dismiss() })
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(ActionStrings.save, action: saveTag)
                        .disabled(viewModel.isArchived)
                }
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .confirmation(let confirmationType):
                    return Alert(
                        title: Text(LabelStrings.confirmation),
                        message: Text(confirmationType.message),
                        primaryButton: confirmationType.alertButton(action: { confirmationAction(confirmationType) }),
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
    }
    
    @ViewBuilder
    func defaultValueFooter() -> some View {
        switch viewModel.gearType {
        case .none:
            Text(NSLocalizedString("Default tags will be applied to all new workouts.", comment: "Gear type none footer"))
        default:
            Text(NSLocalizedString("Default tags will be applied to new workouts based on gear type.", comment: "Gear type footer"))
        }
    }
}

extension TagsAddView {
    
    func saveTag() {
        do {
            try tagManager.addTag(viewModel: viewModel, isInsert: isInsert)
            AnalyticsManager.shared.saveTag(source: source, isNew: isInsert)
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
            activeAlert = .error(message: NSLocalizedString("Unable to archive tag.", comment: "Tag error"))
        }
    }
    
    func restoreTag() {
        do {
            try tagManager.restoreTag(for: viewModel.uuid)
        } catch {
            activeAlert = .error(message: NSLocalizedString("Unable to restore tag.", comment: "Tag error"))
        }
    }
    
    func deleteTag() {
        do {
            try tagManager.deleteTag(for: viewModel.uuid)
        } catch {
            activeAlert = .error(message: NSLocalizedString("Unable to delete tag.", comment: "Tag error"))
        }
    }
    
}

struct TagsAddView_Previews: PreviewProvider {
    static var viewContext = WorkoutsProvider.preview.container.viewContext
    static var tagManager = TagManager(context: viewContext)
    
    static var viewModel: TagEditViewModel = {
        var model = TagEditViewModel(uuid: UUID(), mode: .edit)
        model.isArchived = false
        return model
    }()
    
    static var previews: some View {
        TagsAddView(viewModel: viewModel, source: .manage, isInsert: false)
            .environmentObject(tagManager)
            .preferredColorScheme(.dark)
    }
}
