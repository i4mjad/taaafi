//
//  MainTabView.swift
//  ios
//
//  Created by Amjad Khalfan on 20/02/2026.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 2

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                Text("Home")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Tab("Vault", systemImage: "lock.fill", value: 1) {
                Text("Vault")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Tab("Guard", systemImage: "shield.lefthalf.filled", value: 2) {
                GuardScreen()
            }

            Tab("Community", systemImage: "person.2.fill", value: 3) {
                Text("Community")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Tab("Account", systemImage: "person.fill", value: 4) {
                Text("Account")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(ScreenTimeManager())
}
