//
//  DocumentPicker.swift
//  Workouts
//
//  Created by Axel Rivera on 1/15/21.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIDocumentPickerViewController
    
    @Environment(\.presentationMode) var presentationMode
    var contentTypes: [UTType]
    var asCopy: Bool
    var action: (_ urls: [URL]) -> Void
    
    init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool = true, action: @escaping ([URL]) -> Void) {
        self.contentTypes = contentTypes
        self.asCopy = asCopy
        self.action = action
    }
}

extension DocumentPicker {
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        Log.debug("creating picker with content types: \(contentTypes)")
        
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: contentTypes,
            asCopy: true
        )
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

extension DocumentPicker {
    class Coordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.action(urls)
        }
    }
}
