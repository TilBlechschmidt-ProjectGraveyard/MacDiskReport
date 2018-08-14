//
//  FilesystemScan.swift
//  MacDiskReport
//
//  Created by Til Blechschmidt on 08.08.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation

class ScanManager {
    let fileManager = FileManager.default

    // Root directory
    private let baseURL: URL
    private(set) var baseDirectory: FileSystemNode

    // Progress and current state
    private(set) public var progress: (directories: Int, files: Int) = (0, 0)
    private var currentLayer: [(URL, FileSystemNode)] = []

    private var interrupted: Bool = false
    private var scanInProgress: Bool = false

    // Delegate and file watcher
    public weak var delegate: ScanManagerDelegate?

    init(path: URL) {
        baseURL = path
        baseDirectory = FileSystemNode(rootDirectoryAt: baseURL)

        currentLayer.append((baseURL, baseDirectory))

    }

    func interrupt() {
        interrupted = true
    }

    func continueScan() {
        if scanInProgress {
            return
        }

        scanInProgress = true

        DispatchQueue.global().async {
            // Scan directories until interrupted or none are left
            while !self.currentLayer.isEmpty && !self.interrupted {
                // Autorelease Obj-C objects every now and then
                autoreleasepool {
                    var autoreleaseCounter = 0
                    while autoreleaseCounter < 100000 {
                        // Take a directory from the current layer
                        guard let (location, directory) = self.currentLayer.popLast() else {
                            break
                        }

                        // Scan the directory and append the results to the current layer
                        let discoveredDirectories = directory.scan(manager: self, cachedLocation: location)
                        self.currentLayer += discoveredDirectories

                        // Increment the counters
                        self.progress.files += directory.children.count
                        self.progress.directories += 1
                        autoreleaseCounter += directory.children.count + 1

                        // Notify the delegate
                        let directories = discoveredDirectories.map { $0.1 }
                        self.delegate?.scanManager(self, didDiscoverElements: directories + directory.children)

                        // Look for interrupts
                        if self.interrupted {
                            break
                        }
                    }
                }
            }

            // Notify the delegate about our interruption / us finishing
            if self.interrupted {
                self.delegate?.scanManagerWasInterrupted(self)
            } else {
                self.delegate?.scanManager(self, didFinishScanOf: self.baseDirectory)
            }

            self.interrupted = false
            self.scanInProgress = false
        }
    }
}

protocol ScanManagerDelegate: class {
    func scanManager(_ scanManager: ScanManager, didDiscoverElements: [FileSystemNode])
    func scanManager(_ scanManager: ScanManager, didFinishScanOf: FileSystemNode)
    func scanManagerWasInterrupted(_ scanManager: ScanManager)
}
