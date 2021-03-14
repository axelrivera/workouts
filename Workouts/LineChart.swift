//
//  LineChart.swift
//  Workouts
//
//  Created by Axel Rivera on 3/9/21.
//

import SwiftUI
import Charts

struct LineChart: UIViewRepresentable {
    
    var values = [ChartValue]()
    var avgValue: Double?
    var lineColor = Color.red

    func makeUIView(context: Context) -> LineChartView {
        let chartView = LineChartView()
        chartView.chartDescription.enabled = false
        chartView.dragEnabled = false
        chartView.setScaleEnabled(false)
        chartView.pinchZoomEnabled = false
        chartView.noDataTextColor = .label
        chartView.backgroundColor = UIColor(.chartBackground)
        
        let legend = chartView.legend
        legend.form = .none
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelTextColor = .label
        xAxis.labelCount = 4
        xAxis.centerAxisLabelsEnabled = true
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = true
        xAxis.centerAxisLabelsEnabled = true
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelTextColor = .label
//        leftAxis.axisMaximum = 200
//        leftAxis.axisMinimum = 90
        leftAxis.gridLineDashLengths = [5, 5]
        leftAxis.drawLimitLinesBehindDataEnabled = true
        
        chartView.rightAxis.enabled = false
    
        
        return chartView
    }

    func updateUIView(_ view: LineChartView, context: Context) {
        let xAxis = view.xAxis
        xAxis.valueFormatter = DateValueFormatter()
        
        var dataSets = [LineChartDataSet]()
        
        var dataEntries = [ChartDataEntry]()
        var avgEntries = [ChartDataEntry]()
        
        for i in 0 ..< values.count {
            let value = values[i]
            dataEntries.append(ChartDataEntry(x: Double(i), y: value.value))
            
            if let avgValue = avgValue {
                avgEntries.append(ChartDataEntry(x: Double(i), y: avgValue))
            }
        }
        
        let dataSet = LineChartDataSet(entries: dataEntries, label: "")
        dataSet.setColor(UIColor(lineColor))
        dataSet.drawValuesEnabled = false
        dataSet.lineWidth = 1.0
        dataSet.drawFilledEnabled = true
        dataSet.fillColor = UIColor(lineColor)
        dataSet.fillAlpha = 0.7
        dataSet.drawCirclesEnabled = false
        
        dataSets.append(dataSet)
        
        if !avgEntries.isEmpty {
            let avgDataSet = LineChartDataSet(entries: avgEntries, label: "")
            avgDataSet.setColor(UIColor.label.withAlphaComponent(0.75))
            avgDataSet.drawValuesEnabled = false
            avgDataSet.lineWidth = 2.0
            avgDataSet.lineDashLengths = [3, 3]
            avgDataSet.drawCirclesEnabled = false

            dataSets.append(avgDataSet)
        }
        
        let data = LineChartData(dataSets: dataSets)
        view.data = data
    }

}

struct LineChart_Previews: PreviewProvider {
    
    static var previews: some View {
        LineChart(values: ChartValue.heartRateSamples, avgValue: 140.0)
            .frame(maxWidth: .infinity, maxHeight: 200.0)
            .colorScheme(.dark)
    }
}

