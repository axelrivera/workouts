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
    var entersReaderIfAvailable: Bool? = nil
    
    var url: URL {
        URL(string: urlString)!
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = entersReaderIfAvailable ?? true
        configuration.barCollapsingEnabled = false
        return SFSafariViewController(url: url, configuration: configuration)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {

    }

}
