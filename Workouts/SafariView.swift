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

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        SFSafariViewController(url: URL(string: urlString)!)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {

    }

}
