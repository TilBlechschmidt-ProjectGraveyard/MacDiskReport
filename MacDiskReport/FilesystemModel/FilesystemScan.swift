//
//  FilesystemScan.swift
//  MacDiskReport
//
//  Created by Til Blechschmidt on 08.08.18.
//  Copyright © 2018 Til Blechschmidt and Noah Peeters. All rights reserved.
//

import Foundation



class FilesystemScan {
    let fileManager = FileManager.default
    let baseURL: URL
    var baseDirectory: Directory?

    init(path: URL) {
        baseURL = path
        scan()
    }

    func scan() {
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .isVolumeKey, .nameKey, .fileAllocatedSizeKey]
        let enumerator = fileManager.enumerator(at: baseURL,
                                                includingPropertiesForKeys: resourceKeys,
                                                options: [.skipsPackageDescendants],
                                                errorHandler: { (url, error) -> Bool in
                                                            print("directoryEnumerator error at \(url): ", error)
                                                            return true
                                                })!

        let initialDirectory = Directory(size: 0, location: baseURL, parent: nil)
        var workingDirectory: [Directory] = [initialDirectory]

        let start = Date()
        var fileCount = 0
        var directoryCount = 0

        for case let fileURL as URL in enumerator {
            guard let node = try? fileURL.resourceValues(forKeys: Set(resourceKeys)) else {
                continue
            }

            let isDirectory = node.isDirectory ?? false

            // Skip mounted volumes
            if node.isVolume ?? false {
                enumerator.skipDescendants()
            }

            // Update working directory if we went up
            if enumerator.level < workingDirectory.count {
                workingDirectory = Array(workingDirectory.prefix(upTo: enumerator.level))
            }

            // Handle directory or file
            if isDirectory {
                directoryCount += 1
                let newDirectory = Directory(size: 0, location: fileURL, parent: workingDirectory.last)
                workingDirectory.append(newDirectory)
            } else if let parent = workingDirectory.last {
                fileCount += 1
                let newFile = File(size: node.fileAllocatedSize ?? 0, location: fileURL, parent: parent)
                parent.appendChild(child: newFile)
            }
        }

        let end = -start.timeIntervalSinceNow

        print("Files: \(fileCount), Directories: \(directoryCount)")
        print("Directory size: \(initialDirectory.size / 1024 / 1024 / 1024) GB")
        print("Took \(end.rounded()) seconds")
        baseDirectory = initialDirectory
    }
}
