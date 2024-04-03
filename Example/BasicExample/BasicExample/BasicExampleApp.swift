//
//  BasicExampleApp.swift
//  BasicExample
//
//  Created by Brandon Sneed on 2/23/22.
//

import SwiftUI
import Journify
import JournifyFirebase

@main
struct BasicExampleApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    init() {
        Journify.shared().add(plugin: FirebaseDestination())
    }
}

extension Journify {
    static var main: Journify {
        let analytics = Journify(configuration: Configuration(writeKey: "<YOUR WRITE KEY>")
                    .flushAt(3)
                    .trackApplicationLifecycleEvents(true))
        return analytics
    }
}
