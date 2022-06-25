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
        
        let gridColor = UIColor(.secondary).withAlphaComponent(0.2)
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelTextColor = .label
        xAxis.labelCount = 4
        xAxis.drawLabelsEnabled = true
        xAxis.centerAxisLabelsEnabled = false
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = true
        xAxis.gridColor = gridColor
        xAxis.valueFormatter = MonthValueFormatter()
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelTextColor = .label
        leftAxis.labelCount = 4
        leftAxis.drawLabelsEnabled = true
        leftAxis.drawGridLinesEnabled = true
        leftAxis.gridLineDashLengths = [5, 5]
        leftAxis.gridColor = gridColor
        leftAxis.drawLimitLinesBehindDataEnabled = true
        leftAxis.drawZeroLineEnabled = true
        leftAxis.axisMinimum = 0.0
        
        if let max = values.map( { $0.yValue }).max() {
            leftAxis.axisMaximum = max * 1.2
        }
        
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
        var lastDataEntries = [ChartDataEntry]()
        var avgEntries = [ChartDataEntry]()
        
        let showLastEntries = values.count > 2
        
        if showLastEntries {
            lastDataEntries = values.map { value in
                ChartDataEntry(x: value.xValue, y: value.yValue)
            }
        }
        
        values.enumerated().forEach { (index, value) in
            let isLast = index == values.count - 1
            var yValue: Double
            
            if showLastEntries && isLast {
                yValue = Double.nan
            } else {
                yValue = value.yValue
            }
            
            dataEntries.append(ChartDataEntry(x: value.xValue, y: yValue))
            
            if let avgValue = avgValue, avgValue > 0 {
                avgEntries.append(ChartDataEntry(x: value.xValue, y: avgValue))
            }
        }
        
        if lastDataEntries.isPresent {
            let lastDataSet = LineChartDataSet(entries: lastDataEntries, label: "")
            lastDataSet.setColor(UIColor(lineColor))
            lastDataSet.drawValuesEnabled = false
            lastDataSet.lineWidth = 2.0
            lastDataSet.lineDashLengths = [3, 2]
            lastDataSet.drawFilledEnabled = false
            lastDataSet.drawCirclesEnabled = true
            lastDataSet.circleRadius = 5.0
            lastDataSet.setCircleColor(UIColor(lineColor))

            dataSets.append(lastDataSet)
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
            avgDataSet.setColor(UIColor(.apatite))
            avgDataSet.drawValuesEnabled = false
            avgDataSet.lineWidth = 1.0
            avgDataSet.lineDashLengths = [5, 3]
            avgDataSet.drawCirclesEnabled = false

            dataSets.append(avgDataSet)
        }
        
        let data = LineChartData(dataSets: dataSets)
        view.data = data
        
        if let last = self.values.last {
            Log.debug("last with x: \(last.xValue), y: \(last.yValue)")
            view.xAxis.axisMaximum = last.xValue
        }
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

