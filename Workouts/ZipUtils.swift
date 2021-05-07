//
//  ZipUtils.swift
//  Workouts
//
//  Created by Axel Rivera on 3/18/21.
//

import Foundation
import ZIPFoundation

func unzipFitFile(url: URL) -> URL? {
    let fileManager = FileManager.default
    let destination = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    
    do {
        try fileManager.unzipItem(at: url, to: destination)
    } catch {
        return nil
    }
    
    return try? fileManager.contentsOfDirectory(at: destination, includingPropertiesForKeys: nil).first
}
