//
//  EmptyTagsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/23/21.
//

import SwiftUI
import CoreData

struct EmptyTagsView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    enum DisplayType {
        case tags, selector
    }
    
    let displayType: DisplayType
    var onCreate = {}
    
    var description: String {
        switch displayType {
        case .tags:
            return "Looks like you don't have any tags yet."
        case .selector:
            return "Looks like you don't have any tags yet. Add some default values or create your own."
        }
    }
    
    var body: some View {
        VStack(spacing: 20.0) {
            Text(description)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: createTags) {
                Text("Add Default Tags")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    func createTags() {
        DispatchQueue.main.async {
            TagProvider.createDefaultTags(in: viewContext)
            onCreate()
        }
    }
}

struct EmptyTagsView_Previews: PreviewProvider {
    static var viewContext = WorkoutsProvider.preview.container.viewContext
    
    static var previews: some View {
        EmptyTagsView(displayType: .tags, onCreate: {})
            .environment(\.managedObjectContext, viewContext)
    }
}
