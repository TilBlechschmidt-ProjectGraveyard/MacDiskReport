//
//  AppDelegate.swift
//  MacDiskReport
//
//  Created by Til Blechschmidt on 08.08.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
//        let startURL = try! FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let startURL = URL(fileURLWithPath: "/Users/themegatb")
        _ = FilesystemScan(path: startURL)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
