//
//  TagCloud.swift
//  Workouts
//
//  Created by Axel Rivera on 12/22/21.
//

import SwiftUI

struct TagCloud<Model, V>: View where Model: Hashable, V: View {
    typealias ViewGenerator = (Model) -> V
    
    var models: [Model]
    var viewGenerator: ViewGenerator
    var horizontalSpacing: CGFloat = 10
    var verticalSpacing: CGFloat = 10

    @State private var totalHeight
          = CGFloat.zero       // << variant for ScrollView/List
    //    = CGFloat.infinity   // << variant for VStack

    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)// << variant for ScrollView/List
        //.frame(maxHeight: totalHeight) // << variant for VStack
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(self.models, id: \.self) { models in
                viewGenerator(models)
                    .alignmentGuide(.leading, computeValue: { dimension in
                        if (abs(width - dimension.width) > geometry.size.width) {
                            width = 0
                            height -= dimension.height + verticalSpacing
                        }
                        
                        let result = width
                        if models == self.models.last! {
                            width = 0 //last item
                        } else {
                            width -= dimension.width + horizontalSpacing
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: {dimension in
                        let result = height
                        if models == self.models.last! {
                            height = 0 // last item
                        }
                        return result
                    })
            }
        }.background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}

struct TagCloud_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            Text("Sample Text")
            TagCloud(models: TagLabelViewModel.samples) { viewModel in
                Text(viewModel.name)
                    .font(.fixedSubheadline)
                    .foregroundColor(.primary)
                    .padding(CGFloat(5.0))
                    .background(viewModel.color.opacity(0.3))
                    .cornerRadius(5.0)
            }
        }
    }
}
