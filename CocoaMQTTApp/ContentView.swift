//
//  ContentView.swift
//  CocoaMQTTApp
//
//  Created by Mike Bush on 10/15/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var mqttManager: MQTTManager
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(mqttManager.connectionStatus)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MQTTManager())
    }
}
