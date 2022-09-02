//
//  TimeSelectView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/21/20.
//

import SwiftUI

struct TimeSelectView: View {
    var displayMode: DisplayMode = .hourMinuteSecond
    var action: (_ result: Result) -> Void
    
    private let hours: [Int] = Array(0...23)
    private let minutes: [Int] = Array(0...59)
    private let seconds: [Int] = Array(0...59)
    
    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0
    
    var body: some View {
        Form {
            if displayMode == .hourMinuteSecond {
                Picker(NSLocalizedString("Hours", comment: "Label"), selection: $selectedHours) {
                    ForEach(hours, id: \.self) { hour in
                        Text("\(hour)")
                    }
                }
                .pickerStyle(WheelPickerStyle())
            }
        }
    }
}

extension TimeSelectView {
    enum DisplayMode {
        case hourMinuteSecond
        case minuteSecond
    }
    
    struct Result {
        var displayMode: DisplayMode = .hourMinuteSecond
        var hours: Int = 0
        var minutes: Int = 0
        var seconds: Int = 0
        
        var displayString: String {
            var components = [Int]()
            if displayMode == .hourMinuteSecond && hours > 0 {
                components.append(hours)
            }
            
            components.append(minutes)
            components.append(seconds)
            
            return components.map({ String(format: "%02d", $0) }).joined(separator: ":")
        }
    }
}

struct TimeSelectView_Previews: PreviewProvider {
    static var previews: some View {
        TimeSelectView(displayMode: .hourMinuteSecond) { _ in
            
        }
    }
}
