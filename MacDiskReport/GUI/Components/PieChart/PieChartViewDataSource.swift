//
//  PieChartViewDataSource.swift
//  MacDiskReport
//
//  Created by Noah Peeters on 10.08.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Cocoa

/// The data source of a piechart.
public protocol PieChartViewDataSource: class {
    func numberOfSlices(pieCharView: PieChartView) -> Int
    func pieChartView(_ pieChartView: PieChartView, sizeForSliceAt index: Int) -> Double
    func pieChartView(_ pieChartView: PieChartView, colorForSliceAt index: Int) -> NSColor
    func pieChartView(_ pieChartView: PieChartView, highlightColorForSliceAt index: Int) -> NSColor
}

extension PieChartViewDataSource {
    public func pieChartView(_ pieChartView: PieChartView, highlightColorForSliceAt index: Int) -> NSColor {
        let baseColor = self.pieChartView(pieChartView, colorForSliceAt: index)
        return baseColor.highlight(withLevel: 0.5) ?? baseColor
    }
}
