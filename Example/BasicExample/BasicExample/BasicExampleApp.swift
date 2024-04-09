//
//  BasicExampleApp.swift
//  BasicExample
//
//  Created by Brandon Sneed on 2/23/22.
//

import SwiftUI
import Journify
import JournifyFirebase
import Firebase

@main
struct BasicExampleApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    init() {
        Journify.debugLogsEnabled = true
        let configuration = Configuration(writeKey: "wk_2e3FAENdDb7qMMF4qYRY4q93vQL")
            .trackApplicationLifecycleEvents(true)
            .flushInterval(10)
        Journify.setup(with: configuration)
        Journify.shared().add(plugin: FirebaseDestination())
    }
}
