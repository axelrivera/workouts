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
            TagSelector(
                tags: $tagManager.tags,
                selectedTags: $tagManager.selectedTags,
                defaultAction: tagManager.reloadData) { tag in
                toggleTag(tag)
            }
            .onAppear { tagManager.reloadData() }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: { presentationMode.wrappedValue.dismiss() })
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    
                    Button(action: { activeSheet = .add }) {
                        Label("New Tag", systemImage: "plus.circle.fill")
                            .labelStyle(TitleAndIconLabelStyle())
                    }
                }
            }
            .sheet(item: $activeSheet) { item in
                switch item {
                case .add:
                    TagsAddView(viewModel: Tag.addViewModel(sport: tagManager.sport), source: .selector, isInsert: true)
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
    
    func toggleTag(_ tag: Tag) {
        DispatchQueue.main.async {
            do {
                try tagManager.toggle(tag: tag)
                action?()
            } catch {
                activeAlert = .error(message: "Unable to update tag \(tag.name).")
            }
        }
    }
    
}

struct TagSelectorView_Previews: PreviewProvider {
    static var viewContext = WorkoutsProvider.preview.container.viewContext
    static var workout = WorkoutsProvider.sampleWorkout(moc: viewContext)
    
    static var previews: some View {
        TagSelectorView(tagManager: workout.tagManager())
    }
}
