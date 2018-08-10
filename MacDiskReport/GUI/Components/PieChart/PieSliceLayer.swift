//
//  PieSliceLayer.swift
//  MacDiskReport
//
//  Created by Noah Peeters on 09.08.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Cocoa

class PieSliceLayer: CALayer {
    @objc dynamic var startAngle: CGFloat = 0
    @objc dynamic var endAngle: CGFloat = 0
    var fillColor: CGColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

    override init() {
        super.init()
        setNeedsDisplay()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        if let otherPieSlice = layer as? PieSliceLayer {
            startAngle = otherPieSlice.startAngle
            endAngle = otherPieSlice.endAngle
            fillColor = otherPieSlice.fillColor
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setNeedsDisplay()
    }

    override class func needsDisplay(forKey key: String) -> Bool {
        return ["startAngle", "endAngle"].contains(key) || super.needsDisplay(forKey: key)
    }

    override func draw(in ctx: CGContext) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(center.x, center.y)

        ctx.beginPath()
        ctx.move(to: center)
        ctx.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle * 2 * .pi,
            endAngle: endAngle * 2 * .pi,
            clockwise: true)
        ctx.closePath()
        ctx.setFillColor(fillColor)
        ctx.drawPath(using: .fill)
    }
}
