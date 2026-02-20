//
//  iosApp.swift
//  ios
//
//  Created by Amjad Khalfan on 20/02/2026.
//

import SwiftUI

@main
struct iosApp: App {
    @State private var screenTimeManager = ScreenTimeManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(screenTimeManager)
                .environment(\.locale, Locale(identifier: "ar"))
        }
    }
}
