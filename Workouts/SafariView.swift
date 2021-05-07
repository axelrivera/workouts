//
//  SafariView.swift
//  Workouts
//
//  Created by Axel Rivera on 4/3/21.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let urlString: String
    
    var url: URL {
        URL(string: urlString)!
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = true
        return SFSafariViewController(url: url, configuration: configuration)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {

    }

}
