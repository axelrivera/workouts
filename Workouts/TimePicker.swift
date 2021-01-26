//
//  TimePicker.swift
//  Workouts
//
//  Created by Axel Rivera on 1/16/21.
//

import SwiftUI

struct TimePicker: UIViewRepresentable {
    typealias UIViewType = UIPickerView
    
    enum PickerType {
        case hours, minutes
    }
    
    var pickerType: PickerType
    
    @Binding var totalSeconds: Double
}

extension TimePicker {
    static let maxHours = 23
    static let maxMinutes = 59
    static let maxSeconds = 59
    
    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView(frame: .zero)
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        
        let (h, m, s) = secondsToHoursMinutesSeconds(seconds: Int(totalSeconds))
        var components = [Int]()
       
        if pickerType == .hours {
            let hoursValue = h > Self.maxHours ? 0 : h
            components.append(hoursValue)
        }
        
        let minutesValue = m > Self.maxMinutes ? 0 : m
        components.append(minutesValue)
        
        let secondsValue = s > Self.maxSeconds ? 0 : s
        components.append(secondsValue)
        
        for (component, row) in components.enumerated() {
            picker.selectRow(row, inComponent: component, animated: false)
        }
        
        return picker
    }
    
    func updateUIView(_ uiView: UIPickerView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
}

extension TimePicker {
    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: TimePicker
        private(set) var components: [[Int]]
        
        init(_ parent: TimePicker) {
            self.parent = parent
            components = Self.components(for: parent.pickerType)
        }
        
        class var seconds: [Int] {
            (0 ..< 60).map { $0 }
        }
        
        class var minutes: [Int] {
            seconds
        }
        
        class var hours: [Int] {
            (0 ..< 24).map { $0 }
        }
        
        class func components(for pickerType: PickerType) -> [[Int]] {
            switch pickerType {
            case .hours:
                return [hours, minutes, seconds]
            case .minutes:
                return [minutes, seconds]
            }
        }
        
        static var numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumIntegerDigits = 2
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            return formatter
        }()
        
        var numberFormatter: NumberFormatter {
            Self.numberFormatter
        }
        
        func updateTotalSeconds(pickerView: UIPickerView) {
            var hours = 0
            var minutes = 0
            var seconds = 0
            
            switch parent.pickerType {
            case .hours:
                hours = pickerView.selectedRow(inComponent: 0)
                minutes = pickerView.selectedRow(inComponent: 1)
                seconds = pickerView.selectedRow(inComponent: 2)
            case .minutes:
                minutes = pickerView.selectedRow(inComponent: 0)
                seconds = pickerView.selectedRow(inComponent: 1)
            }
            
            parent.totalSeconds = Double((hours * 3600) + (minutes * 60) + seconds)
        }
        
        // MARK: - UIPickerViewDataSource
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            components.count
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            components[component].count
        }
        
        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            return 80.0
        }
        
        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            60.0
        }
        
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            numberFormatter.string(for: components[component][row])
        }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            updateTotalSeconds(pickerView: pickerView)
        }
    }
}
