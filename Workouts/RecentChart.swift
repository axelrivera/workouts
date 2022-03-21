//
//  RecentChart.swift
//  Workouts
//
//  Created by Axel Rivera on 7/1/21.
//

import SwiftUI
import Charts

struct RecentChart: UIViewRepresentable {
    var values: [ChartInterval]
    var avgValue: Double?
    var lineColor = Color.distance
    var circleColor = Color.primary
    var yAxisFormatter: UnitValueFormatter? = nil
}

extension RecentChart {
    
    func makeUIView(context: Context) -> LineChartView {
        let chartView = LineChartView()
        chartView.isUserInteractionEnabled = false
        chartView.chartDescription.enabled = false
        chartView.dragEnabled = false
        chartView.setScaleEnabled(false)
        chartView.pinchZoomEnabled = false
        chartView.noDataTextColor = .label
        chartView.gridBackgroundColor = .secondarySystemBackground
        chartView.drawGridBackgroundEnabled = false
        
        let legend = chartView.legend
        legend.form = .none
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelTextColor = .label
        xAxis.labelCount = 4
        xAxis.drawLabelsEnabled = true
        xAxis.centerAxisLabelsEnabled = false
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = true
        xAxis.valueFormatter = MonthValueFormatter()
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelTextColor = .label
        leftAxis.labelCount = 4
        leftAxis.drawLabelsEnabled = true
        leftAxis.drawGridLinesEnabled = true
        leftAxis.gridLineDashLengths = [5, 5]
        leftAxis.drawLimitLinesBehindDataEnabled = true
        leftAxis.drawZeroLineEnabled = false
        leftAxis.axisMinimum = 0.0
        
        chartView.rightAxis.enabled = false
    
        return chartView
    }

    func updateUIView(_ view: LineChartView, context: Context) {
        let leftAxis = view.leftAxis
        if let valueFormatter = yAxisFormatter {
            leftAxis.valueFormatter = valueFormatter
        }
        
        var dataSets = [LineChartDataSet]()
        
        var dataEntries = [ChartDataEntry]()
        var avgEntries = [ChartDataEntry]()
        
        values.forEach { (value) in
            dataEntries.append(ChartDataEntry(x: value.xValue, y: value.yValue))
            if let avgValue = avgValue, avgValue > 0 {
                avgEntries.append(ChartDataEntry(x: value.xValue, y: avgValue))
            }
        }
        
        let dataSet = LineChartDataSet(entries: dataEntries, label: "")
        dataSet.setColor(UIColor(lineColor))
        dataSet.drawValuesEnabled = false
        dataSet.lineWidth = 2.0
        dataSet.drawFilledEnabled = false
        dataSet.drawCirclesEnabled = true
        dataSet.circleRadius = 5.0
        dataSet.setCircleColor(UIColor(lineColor))
        
        dataSets.append(dataSet)
        
        if !avgEntries.isEmpty {
            let avgDataSet = LineChartDataSet(entries: avgEntries, label: "")
            avgDataSet.setColor(UIColor(.distance).withAlphaComponent(0.5))
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



struct RecentChart_Previews: PreviewProvider {
    static var values: [ChartInterval] = {
        StatsSummary.weeklySamples().map { (summary) -> ChartInterval in
            ChartInterval(
                xValue: summary.interval.start.timeIntervalSince1970,
                yValue: nativeDistanceToLocalizedUnit(for: summary.distance)
            )
        }.reversed()
    }()
    
    static var previews: some View {
        VStack {
            RecentChart(values: values, avgValue: 100, lineColor: .distance)
                .frame(maxWidth: .infinity, maxHeight: 200.0)
        }
        .preferredColorScheme(.dark)
    }
}

