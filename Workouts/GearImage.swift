//
//  GearImage.swift
//  Workouts
//
//  Created by Axel Rivera on 11/9/21.
//

import SwiftUI

struct GearImage: View {
    let gearType: Tag.GearType
    
    var body: some View {
        switch gearType {
        case .bike:
            Image(systemName: "bicycle")
        case .shoes:
            Image(uiImage: UIImage(named: "shoe-prints-solid")!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22.0)
        case .none:
            Image(systemName: "tag")
        }
    }
}

struct GearImage_Previews: PreviewProvider {
    static var previews: some View {
        GearImage(gearType: .bike)
    }
}
