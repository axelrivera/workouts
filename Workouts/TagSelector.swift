//
//  TagSelector.swift
//  Workouts
//
//  Created by Axel Rivera on 11/21/21.
//

import SwiftUI
import CryptoKit

struct TagSelector: View {
    @Binding var tags: [Tag]
    @Binding var selectedTags: Set<Tag>
        
    var defaultAction = {}
    var toggleAction: (_ tag: Tag) -> Void
        
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 5.0) {
                ForEach(tags, id: \.self) { tag in
                    Button(action: { toggleTag(tag) }) {
                        HStack {
                            GearImage(gearType: tag.gearType)
                                .foregroundColor(tag.colorValue)
                            Text(tag.name)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: isSelected(tag) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(tag.colorValue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(backgroundForTag(tag))
                        .cornerRadius(12.0)
                    }
                }
            }
            .padding()
        }
        .overlay(emptyOverlay())
    }
    
    @ViewBuilder
    func emptyOverlay() -> some View {
        if tags.isEmpty {
            EmptyTagsView(displayType: .selector, onCreate: defaultAction)
        }
    }
}

extension TagSelector {
    
    func isSelected(_ tag: Tag) -> Bool {
        selectedTags.contains(tag)
    }
    
    func backgroundForTag(_ tag: Tag) -> Color {
        if isSelected(tag) {
            return tag.colorValue.opacity(0.25)
        } else {
            return Color.systemFill
        }
    }
    
    func toggleTag(_ tag: Tag) {
        toggleAction(tag)
    }
    
}

struct TagSelector_Previews: PreviewProvider {
    
    static var previews: some View {
        TagSelector(tags: .constant([]), selectedTags: .constant([]), defaultAction: {}) { tag in
            
        }
    }
}
