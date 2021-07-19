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
    var lineColor = Color.distance
    var circleColor = Color.primary
    var yAxisFormatter: UnitValueFormatter? = nil
}

extension RecentChart {
    
    func makeUIView(context: Context) -> LineChartView {
        let chartView = LineChartView()
        chartView.delegate = context.coordinator
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
//        leftAxis.axisMaximum = 200
//        leftAxis.axisMinimum = 90
        
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
        
        values.forEach { (value) in
            dataEntries.append(ChartDataEntry(x: value.xValue, y: value.yValue))
        }
        
        let dataSet = LineChartDataSet(entries: dataEntries, label: "")
        dataSet.setColor(UIColor(lineColor))
        dataSet.drawValuesEnabled = false
        dataSet.lineWidth = 2.0
        dataSet.drawFilledEnabled = false
        dataSet.drawCirclesEnabled = true
        dataSet.circleRadius = 5.0
        dataSet.setCircleColor(UIColor(lineColor))
//        dataSet.circleHoleRadius = 3.0
//        dataSet.circleHoleColor = UIColor(lineColor)
        
        dataSets.append(dataSet)
        
        let data = LineChartData(dataSets: dataSets)
        view.data = data
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
}

extension RecentChart {
    
    class Coordinator: NSObject, ChartViewDelegate {
        var parent: RecentChart
        
        init(_ parent: RecentChart) {
            self.parent = parent
        }
        
        func chartValueNothingSelected(_ chartView: ChartViewBase) {
            Log.debug("nothing selected")
        }
        
        func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
            Log.debug("entry: \(highlight.dataIndex)")
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
            RecentChart(values: values, lineColor: .distance)
                .frame(maxWidth: .infinity, maxHeight: 200.0)
        }
        .preferredColorScheme(.dark)
    }
}

