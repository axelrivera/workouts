//
//  SystemUtils.swift
//  Workouts
//
//  Created by Axel Rivera on 4/3/21.
//

import Foundation

func systemVersionAndBuild() -> (String, String) {
    let dictionary = Bundle.main.infoDictionary!
    let version = dictionary["CFBundleShortVersionString"] as! String
    let build = dictionary["CFBundleVersion"] as! String
    return (version, build)
}

func systemVersionAndBuildString() -> String {
    let (version, build) = systemVersionAndBuild()
    return String(format: "%@ (%@)", version, build)
}
