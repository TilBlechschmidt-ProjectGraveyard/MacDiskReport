//
//  PieChartView.swift
//  MacDiskReport
//
//  Created by Noah Peeters on 08.08.18.
//  Copyright © 2018 Til Blechschmidt and Noah Peeters. All rights reserved.
//

import Cocoa

private let angleAnimationKey = "animationkey.angle"

/// Displays a PieChart with the data it receives from the data source.
public class PieChartView: NSView {
    /// The delegate of the PieChartView which will be informed about user interactions.
    public weak var delegate: PieChartViewDelegate?

    /// The source used to query the data. Changing the source results in a reload.
    public weak var dataSource: PieChartViewDataSource? {
        didSet {
            reload()
        }
    }

    /// The offset of the angle. 1 results in a 360 degree rotation. 0.25 will rotate the first slice to the top.
    public var angleOffset: CGFloat = 0.25

    /// The timing function used for animations.
    public var timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

    /// The duration used for animations
    public var animationDuration: TimeInterval = 0.75

    /// The current total size of all
    private var totalSize: Double = 0

    /// The type of the data manager to store the data shown in the piechart.
    private typealias DataManager = AnimatedVisualizationDataManager<PieChartSlice>

    /// The manager for the dataa shown in the piechart.
    private let dataManager = DataManager()

    private func createSlice(size: Double, color: CGColor, highlightColor: CGColor,
                             startAngle: CGFloat) -> PieChartSlice {
        let sliceLayer = PieSliceLayer()
        sliceLayer.needsDisplayOnBoundsChange = true
        sliceLayer.fillColor = color
        sliceLayer.startAngle = startAngle
        sliceLayer.endAngle = startAngle
        layer?.addSublayer(sliceLayer)
        return PieChartSlice(
            size: size,
            color: color,
            highlightColor: highlightColor,
            sliceLayer: sliceLayer)
    }

    private func clearChart() {
        dataManager.items.forEach {
            $0.data.sliceLayer.removeFromSuperlayer()
        }
        dataManager.clear(keepingCapacity: true)
        totalSize = 0
    }

    /// Reloads all slices from the data source.
    ///
    /// - Parameter animated: Display the changes animated?
    public func reload(animated: Bool = true) {
        guard let dataSource = dataSource else {
            return
        }

        // Clear current view.
        clearChart()

        // Query new slices.
        let allSlices = (0..<dataSource.numberOfSlices(pieCharView: self)).map {
            createSlice(
                size: dataSource.pieChartView(self, sizeForSliceAt: $0),
                color: dataSource.pieChartView(self, colorForSliceAt: $0).cgColor,
                highlightColor: dataSource.pieChartView(self, highlightColorForSliceAt: $0).cgColor,
                startAngle: angleOffset)
        }

        // Populate view with data.
        totalSize = allSlices.sizeSum()
        dataManager.setElements(allSlices)
        updatePaths(animated: animated)
    }

    /// Reloads size and color data of the given slice.
    ///
    /// - Parameters:
    ///   - index: The index of the slice to reload.
    ///   - animated: Display the changes animated?
    public func reloadSlice(atIndex index: Int, animated: Bool = true) {
        guard let dataSource = dataSource else {
            return
        }

        let container = dataManager.staticView[index]

        // Update size
        let oldSize = container.data.size
        let newSize = dataSource.pieChartView(self, sizeForSliceAt: index)
        container.data.size = newSize
        totalSize += newSize - oldSize

        // Update color
        container.data.color = dataSource.pieChartView(self, colorForSliceAt: index).cgColor
        container.data.highlightColor = dataSource.pieChartView(self, highlightColorForSliceAt: index).cgColor
        if highlightedSlice === container {
            container.data.sliceLayer.fillColor = container.data.highlightColor
        } else {
            container.data.sliceLayer.fillColor = container.data.color
        }

        // Recalculate paths
        updatePaths(animated: animated)
    }

    /// Removes an existing slice at the given index.
    ///
    /// - Parameters:
    ///   - index: The index of the slice to remove.
    ///   - animated: Display the changes animated?
    public func removeSlice(atIndex index: Int, animated: Bool = true) {
        let containerToRemove = dataManager.staticView.markElementForDeletion(atIndex: index)
        totalSize -= containerToRemove.data.size
        containerToRemove.data.size = 0
        updatePaths(animated: animated)
    }

    /// Inserts a new slice at the given index.
    ///
    /// - Parameters:
    ///   - index: The index of the new slice.
    ///   - animated: Display the changes animated?
    public func insertSlice(atIndex index: Int, animated: Bool = true) {
        guard let dataSource = dataSource else {
            return
        }

        let startAngle: CGFloat = index == 0 ? angleOffset : {
            let sliceIndex = dataManager.staticView.convertIndexToArrayIndex(index)
            guard let previousSliceLayer = (sliceIndex.map({
                dataManager.items[$0 - 1]
            }) ?? dataManager.items.last)?.data.sliceLayer else {
                return angleOffset
            }
            return previousSliceLayer.presentationOrSelf().endAngle
        }()

        let newSlice = createSlice(
            size: dataSource.pieChartView(self, sizeForSliceAt: index),
            color: dataSource.pieChartView(self, colorForSliceAt: index).cgColor,
            highlightColor: dataSource.pieChartView(self, highlightColorForSliceAt: index).cgColor,
            startAngle: startAngle)

        dataManager.staticView.insertElement(newSlice, at: index)
        totalSize += newSlice.size
        layoutFrames()
        updatePaths(animated: animated)
    }

    /// Moves an existing slice to a new location.
    ///
    /// - Parameters:
    ///   - fromIndex: The index of the slice to move.
    ///   - toIndex: The new index.
    ///   - animated: Display the changes animated?
    public func moveSlice(atIndex fromIndex: Int, to toIndex: Int, animated: Bool = true) {
        removeSlice(atIndex: fromIndex, animated: animated)
        insertSlice(atIndex: toIndex, animated: animated)
    }

    private weak var highlightedSlice: AnimatedVisualizationDataManager<PieChartSlice>.DataContainer? = nil {
        didSet {
            if let oldContainer = oldValue {
                oldContainer.data.sliceLayer.fillColor = oldContainer.data.color
                oldContainer.data.sliceLayer.setNeedsDisplay()
            }
            if let newContainer = highlightedSlice {
                newContainer.data.sliceLayer.fillColor = newContainer.data.highlightColor
                newContainer.data.sliceLayer.setNeedsDisplay()
            }
        }
    }

    private func getSliceIndex(ofLocation location: CGPoint, includeMarkedForDeletion: Bool) -> Int? {
        let center = NSPoint(x: bounds.midX, y: bounds.midY)

        let radius = sqrt(pow(location.x - center.x, 2) + pow(location.y - center.y, 2))
        guard radius <= min(center.x, center.y) else {
            return nil
        }

        let rawAngle = atan2(location.y - center.y, location.x - center.x)
        let angle = (angleOffset - rawAngle / 2 / .pi).normalizedAngle()

        var currentIndex = 0
        for slice in dataManager.items {
            let animatedSliceLayer = slice.data.sliceLayer.presentationOrSelf()
            let isIncluded = !slice.isMarkedForDeletion || includeMarkedForDeletion
            if angleOffset - animatedSliceLayer.startAngle < angle &&
                angleOffset - animatedSliceLayer.endAngle > angle {
                return isIncluded ? currentIndex : nil
            }
            if isIncluded {
                currentIndex += 1
            }
        }

        return nil
    }
}

// MARK: - Mouse Events
extension PieChartView {
    // MARK: Setup

    /// Creates a new tracking area to capture mouse events.
    private func createTrackingArea() {
        self.addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.activeInActiveApp, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil))
    }

    public override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        createTrackingArea()
    }

    // MARK: Events
    public override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        let location = self.convert(event.locationInWindow, from: nil)
        let sliceIndex = getSliceIndex(ofLocation: location, includeMarkedForDeletion: true)
        highlightedSlice = sliceIndex.map { dataManager.animationView[$0] }
    }

    public override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        let location = self.convert(event.locationInWindow, from: nil)
        if let clickedSliceIndex = getSliceIndex(ofLocation: location, includeMarkedForDeletion: false) {
            delegate?.pieChartView(self, didClickSlice: clickedSliceIndex)
        }
    }

    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        highlightedSlice = nil
    }
}

// MARK: - Create paths
extension PieChartView {
    private func createBasicAnimation(for keyPath: String, from fromValue: Any?, to toValue: Any?) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.duration = animationDuration
        animation.timingFunction = timingFunction
        animation.fromValue = fromValue
        animation.toValue = toValue
        return animation
    }

    public func updatePaths(animated: Bool) {
        var startAngle = angleOffset

        for container in dataManager.items {
            let slice = container.data
            let angle = CGFloat(slice.size)/CGFloat(totalSize)
            let endAngle = startAngle - angle

            if animated {
                let animationGroup = CAAnimationGroup()
                animationGroup.animations = [
                    createBasicAnimation(
                        for: "startAngle",
                        from: slice.sliceLayer.presentationOrSelf().startAngle,
                        to: startAngle),
                    createBasicAnimation(
                        for: "endAngle",
                        from: slice.sliceLayer.presentationOrSelf().endAngle,
                        to: endAngle)
                ]
                animationGroup.duration = animationDuration
                animationGroup.isRemovedOnCompletion = true
                animationGroup.delegate = self
                animationGroup.completionBlock = { finished in
                    if finished, container.isMarkedForDeletion {
                        self.dataManager.removeContainer(container)
                        container.data.sliceLayer.removeFromSuperlayer()
                    }
                }
                slice.sliceLayer.add(animationGroup, forKey: angleAnimationKey)
            }

            slice.sliceLayer.endAngle = endAngle
            slice.sliceLayer.startAngle = startAngle

            startAngle = endAngle
        }
    }
}

// MARK: - Layout
extension PieChartView {
    public override func layout() {
        super.layout()

        layoutFrames()
        updatePaths(animated: false)
    }

    private func layoutFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        dataManager.items.forEach {
            $0.data.sliceLayer.frame = self.bounds
        }
        CATransaction.commit()
    }
}

extension PieChartView: CAAnimationDelegate {
    public func animationDidStop(_ animation: CAAnimation, finished: Bool) {
        animation.completionBlock?(finished)
    }
}

private struct PieChartSlice {
    var size: Double
    var color: CGColor
    var highlightColor: CGColor
    let sliceLayer: PieSliceLayer
}

extension Collection where Element == PieChartSlice {
    func sizeSum() -> Double {
        return reduce(0) { $0 + $1.size }
    }
}

extension CGFloat {
    fileprivate func normalizedAngle() -> CGFloat {
        return self - floor(self)
    }
}
