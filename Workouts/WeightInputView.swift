//
//  WeightInputView.swift
//  Workouts
//
//  Created by Axel Rivera on 3/22/21.
//

import SwiftUI

struct WeightInputView: View {
    let weights = (0 ... 500).map({ $0 })
    
    @Binding var weight: Double
    @State private var selectedIndex = 0
    
    var weightValue: Double {
        Double(weights[selectedIndex])
    }
    
    var body: some View {
        Form {
            Section(footer: Text("Better Workouts uses weight to estimate calories burned for energy samples when importing workouts.")) {
                HStack {
                    Text("Your Weight")
                    Spacer()
                    Text(formattedLocalizedWeightString(for: weightValue))
                }
                
                Picker(selection: $selectedIndex, label: Text("Picker"), content: {
                    ForEach(0 ..< weights.count, id: \.self) { index in
                        Text(formattedLocalizedWeightString(for: Double(weights[index])))
                    }
                })
                .onAppear(perform: {
                    updateSelectedIndex()
                })
                .onChange(of: selectedIndex, perform: { value in
                    weight = localizedWeightUnitToKilograms(for: weightValue)
                    AppSettings.weight = weight
                })
                .pickerStyle(WheelPickerStyle())
            }
        }
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension WeightInputView {
    
    func updateSelectedIndex() {
        let value = Int(kilogramsToLocalizedWeightUnit(for: weight))
        selectedIndex = weights.firstIndex(where: { $0 == value }) ?? 0
    }
    
}

struct WeightInputView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WeightInputView(weight: .constant(72.0))
        }
    }
}
