//
//  PieChartViewDelegate.swift
//  MacDiskReport
//
//  Created by Noah Peeters on 10.08.18.
//  Copyright © 2018 Til Blechschmidt and Noah Peeters. All rights reserved.
//

import Foundation

public protocol PieChartViewDelegate: class {
    func pieChartView(_ pieChartView: PieChartView, didClickSlice index: Int)
}
