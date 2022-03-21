//
//  ImageActivitySheet.swift
//  Workouts
//
//  Created by Axel Rivera on 8/23/21.
//

import SwiftUI

struct ImageActivitySheet: UIViewControllerRepresentable {
    enum ImageType: String {
        case png, jpg
    }
    
    let image: UIImage
    let imageType: ImageType
    let imageName: String?
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let activityItems: [Any]
        if let url = imageURL {
            activityItems = [url]
        } else {
            activityItems = []
        }
        
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    var imageURL: URL? {
        var data: Data?
        
        switch imageType {
        case .png:
            data = image.pngData()
        case .jpg:
            data = image.jpegData(compressionQuality: 1.0)
        }
        
        guard let data = data else { return nil }
        let fileName = imageName ?? "Image"
        
        let directory = FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent(fileName)
            .appendingPathExtension(imageType.rawValue)
        
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
    
}

