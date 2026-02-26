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
            Tab(Strings.Tab.home, systemImage: "house.fill", value: 0) {
                HomeScreen()
            }

            Tab(Strings.Tab.vault, systemImage: "lock.fill", value: 1) {
                Text(Strings.Tab.vault)
                    .font(Typography.h4)
                    .foregroundStyle(AppColors.grey500)
            }

            Tab(Strings.Tab.guard, systemImage: "shield.lefthalf.filled", value: 2) {
                GuardScreen()
            }

            Tab(Strings.Tab.community, systemImage: "person.2.fill", value: 3) {
                Text(Strings.Tab.community)
                    .font(Typography.h4)
                    .foregroundStyle(AppColors.grey500)
            }

            Tab(Strings.Tab.account, systemImage: "person.fill", value: 4) {
                Text(Strings.Tab.account)
                    .font(Typography.h4)
                    .foregroundStyle(AppColors.grey500)
            }
        }
        .tint(AppColors.primary)
    }
}

#Preview {
    MainTabView()
        .environment(ScreenTimeManager())
}
