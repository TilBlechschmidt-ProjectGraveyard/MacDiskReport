//
//  CAAnimation+Completion.swift
//  MacDiskReport
//
//  Created by Noah Peeters on 10.08.18.
//  Copyright © 2018 Til Blechschmidt and Noah Peeters. All rights reserved.
//

import Cocoa

extension CAAnimation {
    public typealias CompletionBlock = (Bool) -> Void

    private static let completionBlockKey = "to.us.peeters.animationcompletionblock"

    public var completionBlock: CompletionBlock? {
        get {
            return value(forKey: CAAnimation.completionBlockKey) as? CompletionBlock? ?? nil
        }
        set {
            setValue(newValue, forKey: CAAnimation.completionBlockKey)
        }
    }
}
