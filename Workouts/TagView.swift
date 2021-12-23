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
    let viewModel: TagLabelViewModel
    
    var body: some View {
        Text(viewModel.name)
            .font(.fixedSubheadline)
            .foregroundColor(.primary)
            .padding(CGFloat(5.0))
            .background(viewModel.color.opacity(0.3))
            .cornerRadius(5.0)
    }
}

struct TagView_Previews: PreviewProvider {
    static var tags = TagLabelViewModel.samples
    
    static var previews: some View {
        Form {
            TagGrid(tags: tags)
            TagLine(tags: tags)
        }
    }
}

struct TagGrid: View {
    var tags: [TagLabelViewModel]
    
    var body: some View {
        TagCloud(models: tags) {
            TagView(viewModel: $0)
        }
        .padding([.top, .bottom], 5.0)
    }
    
}

struct TagLine: View {
    var tags: [TagLabelViewModel]
    
    let rows: [GridItem] = [.init(.flexible(minimum: 0, maximum: 0))]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: rows, alignment: .center, spacing: 10.0) {
                ForEach(tags, id: \.id) { tag in
                    TagView(viewModel: tag)
                }
            }
        }
        .frame(height: 44.0, alignment: .center)
    }
    
    
}
