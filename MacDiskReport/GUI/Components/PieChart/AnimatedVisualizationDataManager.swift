//
//  AnimatedVisualizationDataManager.swift
//  MacDiskReport
//
//  Created by Noah Peeters on 10.08.18.
//  Copyright © 2018 Til Blechschmidt and Noah Peeters. All rights reserved.
//

import Foundation

public class AnimatedVisualizationDataManager<Element> {
    fileprivate(set) public var items: [DataContainer] = []

    public init() {}

    private(set) public lazy var animationView: AnimatedVisualizationDataManagerView<Element> = {
        AnimatedVisualizationDataManagerView(dataManager: self, includeMarkedForDeletion: true)
    }()

    private(set) public lazy var staticView: AnimatedVisualizationDataManagerView<Element> = {
        AnimatedVisualizationDataManagerView(dataManager: self, includeMarkedForDeletion: false)
    }()

    public class DataContainer {
        public var data: Element
        private(set) public var isMarkedForDeletion = false

        fileprivate func markForDeletion() {
            isMarkedForDeletion = true
        }

        fileprivate init(data: Element) {
            self.data = data
        }
    }

    public func clear(keepingCapacity: Bool) {
        items.removeAll(keepingCapacity: keepingCapacity)
    }

    public func setElements(_ elements: [Element]) {
        items = elements.map { DataContainer(data: $0) }
    }

    @discardableResult
    public func removeContainer(_ element: DataContainer) -> Bool {
        guard let indexToRemove = items.firstIndex(where: { $0 === element }) else {
            return false
        }

        items.remove(at: indexToRemove)
        return true
    }
}

public class AnimatedVisualizationDataManagerView<Element> {
    public typealias DataManager = AnimatedVisualizationDataManager<Element>
    public typealias DataContainer = DataManager.DataContainer
    private let dataManager: AnimatedVisualizationDataManager<Element>
    private let includeMarkedForDeletion: Bool

    fileprivate init(dataManager: DataManager, includeMarkedForDeletion: Bool) {
        self.dataManager = dataManager
        self.includeMarkedForDeletion = includeMarkedForDeletion
    }

    public func convertIndexToArrayIndex(_ index: Int) -> Int? {
        if includeMarkedForDeletion {
            return index
        } else {
            var searchIndex = -1

            for (elementIndex, element) in dataManager.items.enumerated() where !element.isMarkedForDeletion {
                searchIndex += 1
                if searchIndex == index {
                    return elementIndex
                }
            }

            return nil
        }
    }

    subscript(_ index: Int) -> DataContainer {
        return dataManager.items[convertIndexToArrayIndex(index)!]
    }

    public func markElementForDeletion(atIndex index: Int) -> DataContainer {
        let container = dataManager.items[convertIndexToArrayIndex(index)!]
        container.markForDeletion()
        return container
    }

    @discardableResult
    public func insertElement(_ element: Element, at index: Int) -> DataContainer {
        let container = DataContainer(data: element)
        if let arrayIndex = convertIndexToArrayIndex(index) {
            dataManager.items.insert(container, at: arrayIndex)
        } else {
            dataManager.items.append(container)
        }
        return container
    }
}
