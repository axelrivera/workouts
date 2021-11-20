//
//  TagView.swift
//  Workouts
//
//  Created by Axel Rivera on 10/27/21.
//

import SwiftUI


extension TagLabelViewModel {
    
    static var samples: [TagLabelViewModel] {
        [
            TagLabelViewModel.sample(name: "Tag 1"),
            TagLabelViewModel.sample(name: "Tag 2"),
            TagLabelViewModel.sample(name: "Tag 3"),
            TagLabelViewModel.sample(name: "Long Text Tag 4"),
            TagLabelViewModel.sample(name: "Tag 5"),
            TagLabelViewModel.sample(name: "Tag 6"),
            TagLabelViewModel.sample(name: "Tag 7"),
            TagLabelViewModel.sample(name: "Tag 8"),
            TagLabelViewModel.sample(name: "Tag 9"),
            TagLabelViewModel.sample(name: "Tag 10"),
            TagLabelViewModel.sample(name: "Tag 11"),
        ]
    }
    
}

struct TagView: View {
    let name: String
    let color: Color
    
    var body: some View {
        Text(name)
            .font(.fixedSubheadline)
            .foregroundColor(.primary)
            .padding(CGFloat(5.0))
            .background(color.opacity(0.3))
            .cornerRadius(5.0)
    }
}

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagGrid(tags: TagLabelViewModel.samples)
            .padding()
    }
}

struct TagGrid: View {
    let tags: [TagLabelViewModel]
    
    var body: some View {
        WrappingHStack(tags, id: \.self, alignment: .leading, spacing: .constant(10.0)) { tag in
            TagView(name: tag.name, color: tag.color)
                .padding([.top, .bottom], 5.0)
        }
    }
    
}
