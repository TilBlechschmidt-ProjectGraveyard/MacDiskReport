//
//  FilesystemNode.swift
//  MacDiskReport
//
//  Created by Til Blechschmidt on 08.08.18.
//  Copyright © 2018 Til Blechschmidt and Noah Peeters. All rights reserved.
//

import Foundation

protocol FilesystemNode {
    var size: Int { get }
    var location: URL { get }
    var parent: Directory? { get }

    init(size: Int, location: URL, parent: Directory?)
}

extension FilesystemNode {
    var name: String {
        return location.lastPathComponent
    }
}
