//
//  WebContent.swift
//  Workouts
//
//  Created by Axel Rivera on 4/3/21.
//

import SwiftUI

struct WebContent: View {
    let title: String
    let urlString: String
    
    var body: some View {
        WebView(urlString: urlString)
            .navigationBarTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct WebContent_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WebContent(title: "Sample Title", urlString: "https://www.apple.com")
        }
    }
}
