//
//  LineChart.swift
//  Workouts
//
//  Created by Axel Rivera on 3/9/21.
//

import SwiftUI
import Charts

struct LineChart: UIViewRepresentable {
    var valueType: ChartInterval.ValueType
    var values = [ChartInterval]()
    var avgValue: Double?
    
    private var lineColor = Color.red
    private var yAxisFormatter: AxisValueFormatter? = nil
    
    init(valueType: ChartInterval.ValueType, values: [ChartInterval], avg: Double?) {
        self.valueType = valueType
        self.values = values
        self.avgValue = avg
        
        switch valueType {
        case .heartRate:
            self.lineColor = .calories
        case .speed:
            self.lineColor = .speed
        case .cadence:
            self.lineColor = .cadence
        case .pace:
            self.lineColor = .pace
            self.yAxisFormatter = PaceValueFormatter()
        case .altitude:
            self.lineColor = .elevation
        }
    }

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
        xAxis.centerAxisLabelsEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = true
        xAxis.valueFormatter = DateValueFormatter()
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelTextColor = .label
        
        leftAxis.gridLineDashLengths = [5, 5]
        leftAxis.drawLimitLinesBehindDataEnabled = true
        
        if let valueFormatter = yAxisFormatter {
            leftAxis.valueFormatter = valueFormatter
        }
        
        chartView.rightAxis.enabled = false
    
        return chartView
    }

    func updateUIView(_ view: LineChartView, context: Context) {
        var dataSets = [LineChartDataSet]()
        
        var dataEntries = [ChartDataEntry]()
        var avgEntries = [ChartDataEntry]()
        
        values.forEach { value in
            dataEntries.append(ChartDataEntry(x: value.xValue, y: value.yValue))
            if let avgValue = avgValue {
                avgEntries.append(ChartDataEntry(x: value.xValue, y: avgValue))
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
        LineChart(valueType: .heartRate, values: [], avg: 140.0)
            .frame(maxWidth: .infinity, maxHeight: 200.0)
            .colorScheme(.dark)
    }
}

