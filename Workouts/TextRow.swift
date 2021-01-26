//
//  TextRow.swift
//  Workouts
//
//  Created by Axel Rivera on 1/16/21.
//

import SwiftUI

struct TextRow: View {
    var item: RowItem
    
    var body: some View {
        HStack {
            Text(item.text)
            
            if let detail = item.detail {
                Spacer()
                Text(detail)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TextRow_Previews: PreviewProvider {
    
    static var previews: some View {
        TextRow(item: RowItem(text: "Text", detail: "Detail"))
    }
}
