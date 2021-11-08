//
//  TagSelectorView.swift
//  Workouts
//
//  Created by Axel Rivera on 10/28/21.
//

import SwiftUI

struct TagSelectorView: View {
    enum ActiveSheet: Identifiable {
        case add
        var id: Int { hashValue }
    }
    
    enum ActiveAlert: Hashable, Identifiable {
        case error(message: String)
        var id: Self { self }
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject var tagManager: TagManager
    
    @State private var activeSheet: ActiveSheet?
    @State private var activeAlert: ActiveAlert?
    
    var action: (() -> Void)?
    
    init(tagManager: TagManager, action: (() -> Void)? = nil) {
        _tagManager = StateObject(wrappedValue: tagManager)
        self.action = action
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 5.0) {
                    ForEach(tagManager.tags, id: \.self) { tag in
                        Button(action: { toggleTag(tag) }) {
                            HStack {
                                Image(systemName: tagManager.isSelected(tag: tag) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(tag.colorValue)
                                Text(tag.name)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(backgroundForTag(tag))
                            .cornerRadius(12.0)
                        }
                    }
                }
                .padding()
                .onAppear { tagManager.reloadData() }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Tag", action: { activeSheet = .add })
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: { presentationMode.wrappedValue.dismiss() })
                }
            }
            .sheet(item: $activeSheet) { item in
                switch item {
                case .add: 
                    TagsAddView(viewModel: Tag.addViewModel(sport: tagManager.sport))
                        .environmentObject(tagManager)
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

extension TagSelectorView {
    
    func backgroundForTag(_ tag: Tag) -> Color {
        if tagManager.isSelected(tag: tag) {
            return tag.colorValue.opacity(0.25)
        } else {
            return Color.systemFill
        }
    }
    
    func toggleTag(_ tag: Tag) {
        do {
            try tagManager.toggle(tag: tag)
            action?()
        } catch {
            activeAlert = .error(message: "Unable to update tag \(tag.name).")
        }
    }
    
}

struct TagSelectorView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var workout = StorageProvider.sampleWorkout(moc: viewContext)
    
    static var previews: some View {
        TagSelectorView(tagManager: workout.tagManager())
    }
}
