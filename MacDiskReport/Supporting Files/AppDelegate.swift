//
//  AppDelegate.swift
//  MacDiskReport
//
//  Created by Til Blechschmidt on 08.08.18.
//  Copyright © 2018 Til Blechschmidt and Noah Peeters. All rights reserved.
//

import Cocoa

class TestDelegate: ScanManagerDelegate {
    var counter = 0

    func scanManager(_ scanManager: ScanManager, didFinishScanOf: FileSystemNode) {
        print("Scan was finished")
        print(scanManager.progress)
        print("\(scanManager.baseDirectory.size / 1024 / 1024 / 1024) GB")
    }

    func scanManager(_ scanManager: ScanManager, didDiscoverElements: [FileSystemNode]) {
        counter += 1
        if counter % 10000 == 0 {
            print(scanManager.progress)
            counter = 0
        }
    }

    func scanManagerWasInterrupted(_ scanManager: ScanManager) {
        print("Scan got interrupted")
        print(scanManager.progress)
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    let test = TestDelegate()
    let manager = ScanManager(path: URL(fileURLWithPath: "/Users/themegatb/"))

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        manager.delegate = test
        manager.continueScan()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
