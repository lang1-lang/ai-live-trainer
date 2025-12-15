//
//  ContentView.swift
//  AI Live Trainer System
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeLibraryView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            ActivityView()
                .tabItem {
                    Label("Activity", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            AIInsightsView()
                .tabItem {
                    Label("AI Insights", systemImage: "brain.head.profile")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}

