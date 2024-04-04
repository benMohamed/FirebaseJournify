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
        Journify.debugLogsEnabled = true
        Journify.shared().add(plugin: FirebaseDestination())
    }
}

extension Journify {
    static var main: Journify {
        let analytics = Journify(configuration: Configuration(writeKey: "wk_test_2e3FAENdDb7qMMF4qYRY4q93vQL")
                    .flushAt(3)
                    .trackApplicationLifecycleEvents(true))
        return analytics
    }
}
