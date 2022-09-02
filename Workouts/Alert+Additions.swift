//
//  Alert+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 7/15/21.
//

import SwiftUI

extension Alert {
    
    static func showAlertWithTitle(_ title: String, message: String, action: @escaping () -> Void) -> Alert {
        let continueButton = Alert.Button.default(
            Text(Localization.Actions.continue),
            action: action
        )
        let cancelButton = Alert.Button.cancel()
                            
        return Alert(
            title:  Text(title),
            message: Text(message),
            primaryButton: continueButton,
            secondaryButton: cancelButton
        )
    }
    
}
