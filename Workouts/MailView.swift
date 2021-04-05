//
//  MailView.swift
//  Workouts
//
//  Created by Axel Rivera on 4/5/21.
//

import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
    var recepients: [String]
    var subject: String
    var body: String
    
    static var canSendEmail: Bool {
        MFMailComposeViewController.canSendMail()
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let mailController = MFMailComposeViewController()
        mailController.navigationBar.tintColor = UIColor(.accentColor)
        mailController.mailComposeDelegate = context.coordinator
        mailController.setToRecipients(recepients)
        mailController.setSubject(subject)
        mailController.setMessageBody(body, isHTML: false)
        return mailController
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                context: UIViewControllerRepresentableContext<MailView>) {

    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

extension MailView {
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        
        init(_ parent: MailView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            controller.dismiss(animated: true, completion: nil)
        }
    }
    
}
