//
//  WebView.swift
//  Workouts
//
//  Created by Axel Rivera on 4/3/21.
//

import SwiftUI
import WebKit

struct WebView : UIViewRepresentable {
    
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView  {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: URL(string: urlString)!)
        uiView.load(request)
    }
    
}

#if DEBUG
struct WebView_Previews : PreviewProvider {
    static var previews: some View {
        WebView(urlString: "https://www.apple.com")
    }
}
#endif
