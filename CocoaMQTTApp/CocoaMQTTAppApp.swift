//
//  CocoaMQTTAppApp.swift
//  CocoaMQTTApp
//
//  Created by Mike Bush on 10/15/24.
//

import SwiftUI
import CocoaMQTT

@main
struct CocoaMQTTAppApp: App {
    
    @StateObject private var mqttManager = MQTTManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mqttManager)
        }
    }
}
