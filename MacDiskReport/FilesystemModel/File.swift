//
//  File.swift
//  MacDiskReport
//
//  Created by Til Blechschmidt on 08.08.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation

class File: FilesystemNode {
    // MARK: FilesystemNode
    var size: Int
    var location: URL
    var parent: Directory?

    required init(size: Int, location: URL, parent: Directory?) {
        self.size = size
        self.location = location
        self.parent = parent
    }
}
