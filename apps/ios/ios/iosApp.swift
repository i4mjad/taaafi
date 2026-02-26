//
//  iosApp.swift
//  ios
//
//  Created by Amjad Khalfan on 20/02/2026.
//

import SwiftUI
import FirebaseCore

@main
struct iosApp: App {
    @State private var screenTimeManager = ScreenTimeManager()

    // Core Services (initialized in init after FirebaseApp.configure)
    @State private var errorLogger = ErrorLogger()
    @State private var analytics: AnalyticsFacade
    @State private var authService: AuthService
    @State private var firestoreService: FirestoreService
    @State private var cloudFunctionsService: CloudFunctionsService
    @State private var storageService: StorageService
    @State private var emailSyncService: EmailSyncService

    // Services requiring shared initialization
    @State private var deviceTrackingService: DeviceTrackingService
    @State private var banWarningFacade: BanWarningFacade
    @State private var routeSecurityService: RouteSecurityService
    @State private var startupSecurityService: StartupSecurityService

    // Startup state
    @State private var startupResult: SecurityStartupResult?
    @State private var isStartupComplete = false

    init() {
        FirebaseApp.configure()

        // Firebase-dependent services (must initialize after FirebaseApp.configure)
        _analytics = State(initialValue: AnalyticsFacade())
        _authService = State(initialValue: AuthService())
        _firestoreService = State(initialValue: FirestoreService())
        _cloudFunctionsService = State(initialValue: CloudFunctionsService())
        _storageService = State(initialValue: StorageService())
        _emailSyncService = State(initialValue: EmailSyncService())

        // Single DeviceTrackingService shared by all security services
        let deviceTracking = DeviceTrackingService()
        let facade = BanWarningFacade(deviceTrackingService: deviceTracking)

        _deviceTrackingService = State(initialValue: deviceTracking)
        _banWarningFacade = State(initialValue: facade)
        _routeSecurityService = State(initialValue: RouteSecurityService(facade: facade))
        _startupSecurityService = State(initialValue: StartupSecurityService(facade: facade))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !isStartupComplete {
                    startupView
                } else if let result = startupResult, result.isBlocked {
                    bannedView(result: result)
                } else {
                    MainTabView()
                }
            }
            .environment(screenTimeManager)
            .environment(errorLogger)
            .environment(analytics)
            .environment(authService)
            .environment(firestoreService)
            .environment(cloudFunctionsService)
            .environment(storageService)
            .environment(deviceTrackingService)
            .environment(emailSyncService)
            .environment(routeSecurityService)
            .environment(\.locale, Locale(identifier: "ar"))
            .task {
                // Configure auth service with dependencies
                authService.configure(analytics: analytics, errorLogger: errorLogger)

                // Start device tracking auth listener
                deviceTrackingService.startListeningToAuthState()

                // Run startup security check
                let result = await startupSecurityService.initializeAppSecurity()
                startupResult = result
                isStartupComplete = true

                // Post-startup tasks (only if not blocked)
                if !result.isBlocked {
                    analytics.trackAppOpened()
                    await emailSyncService.syncUserEmailIfNeeded()
                }
            }
        }
    }

    // MARK: - Startup Views

    private var startupView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func bannedView(result: SecurityStartupResult) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)

            Text("Access Restricted")
                .font(.title2.bold())

            Text(result.message ?? "Your access has been restricted.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
