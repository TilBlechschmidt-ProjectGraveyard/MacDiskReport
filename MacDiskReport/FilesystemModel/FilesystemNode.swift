//
//  FileSystemNode.swift
//  MacDiskReport
//
//  Created by Til Blechschmidt on 08.08.18.
//  Copyright © 2018 Til Blechschmidt and Noah Peeters. All rights reserved.
//

import Foundation

enum FileSystemNodeType: Int, Codable {
    case file = 0
    case directory = 1
    case other = 2
}

class FileSystemNode: Codable {
    let name: String
    let type: FileSystemNodeType
    private(set) var size: Int
    private(set) weak var parent: FileSystemNode?

    init(rootDirectoryAt location: URL) {
        size = 0
        self.name = location.path
        self.type = .directory

        children.reserveCapacity(20)
    }

    init(directoryAt location: URL) {
        size = 0
        self.name = location.lastPathComponent
        self.type = .directory

        children.reserveCapacity(20)
    }

    init(fileAt location: URL, withSize size: Int) {
        self.name = location.lastPathComponent
        self.type = .file
        self.size = size
    }

    // MARK: Directory
    var children: [FileSystemNode] = []
    private static let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .isVolumeKey, .fileAllocatedSizeKey]
    private static let resourceKeySet: Set<URLResourceKey> = Set(resourceKeys)
    private static let scanOptions: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants,
                                                                               .skipsSubdirectoryDescendants]

    func increaseSize(by value: Int) {
        size += value
        parent?.increaseSize(by: value)
    }

    func appendChild(child: FileSystemNode) {
        child.parent = self
        children.append(child)
        if child.size != 0 {
            increaseSize(by: child.size)
        }
    }

    static func scanDirectory(manager: ScanManager, location: URL) -> [URL]? {
        return try? manager.fileManager.contentsOfDirectory(at: location,
                                                            includingPropertiesForKeys: FileSystemNode.resourceKeys,
                                                            options: scanOptions)
    }

    func scan(manager: ScanManager, cachedLocation: URL) -> [(URL, FileSystemNode)] {
        guard let childNodes = FileSystemNode.scanDirectory(manager: manager, location: cachedLocation) else {
            return []
        }

        var subDirectories: [(URL, FileSystemNode)] = []
        for childPath in childNodes {
            let resourceValues = try? childPath.resourceValues(forKeys: FileSystemNode.resourceKeySet)
            guard let node = resourceValues, !(node.isVolume ?? false) else {
                continue
            }

            if node.isDirectory ?? false {
                let directory = FileSystemNode(directoryAt: childPath)
                appendChild(child: directory)
                subDirectories.append((childPath, directory))
            } else {
                let file = FileSystemNode(fileAt: childPath, withSize: node.fileAllocatedSize ?? 0)
                appendChild(child: file)
            }
        }

        return subDirectories
    }
}

extension FileSystemNode {
    var location: URL {
        guard let parent = parent else {
            return URL(fileURLWithPath: name)
        }

        return parent.location.appendingPathComponent(name)
    }
}
