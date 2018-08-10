//
//  CALayer+Presentation.swift
//  MacDiskReport
//
//  Created by Noah Peeters on 11.08.18.
//  Copyright © 2018 Til Blechschmidt and Noah Peeters. All rights reserved.
//

import Cocoa

extension CALayer {
    internal func presentationOrSelf() -> Self {
        return presentation() ?? self
    }
}
