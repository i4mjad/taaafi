//
//  iosApp.swift
//  ios
//
//  Created by Amjad Khalfan on 20/02/2026.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct iosApp: App {
    @State private var screenTimeManager = ScreenTimeManager()
    @State private var toastManager = ToastManager()

    // Core Services (initialized in init after FirebaseApp.configure)
    @State private var errorLogger = ErrorLogger()
    @State private var analytics: AnalyticsFacade
    @State private var authService: AuthService
    @State private var firestoreService: FirestoreService
    @State private var cloudFunctionsService: CloudFunctionsService
    @State private var storageService: StorageService
    @State private var emailSyncService: EmailSyncService
    @State private var userDocumentService: UserDocumentService

    // Services requiring shared initialization
    @State private var deviceTrackingService: DeviceTrackingService
    @State private var banWarningFacade: BanWarningFacade
    @State private var routeSecurityService: RouteSecurityService
    @State private var startupSecurityService: StartupSecurityService

    // Startup state
    @State private var startupResult: SecurityStartupResult?
    @State private var isStartupComplete = false

    init() {
        AppAppearance.configure()
        FirebaseApp.configure()

        // Firebase-dependent services (must initialize after FirebaseApp.configure)
        let firestore = FirestoreService()
        _analytics = State(initialValue: AnalyticsFacade())
        _authService = State(initialValue: AuthService())
        _firestoreService = State(initialValue: firestore)
        _cloudFunctionsService = State(initialValue: CloudFunctionsService())
        _storageService = State(initialValue: StorageService())
        _emailSyncService = State(initialValue: EmailSyncService())
        _userDocumentService = State(initialValue: UserDocumentService(firestoreService: firestore))

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
                    AuthRouter()
                }
            }
            .toastOverlay()
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
            .environment(userDocumentService)
            .environment(toastManager)
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

                    // Start/stop UserDocumentService listener based on auth state
                    if let uid = authService.currentUser?.uid {
                        userDocumentService.startListening(userId: uid)
                    } else {
                        userDocumentService.stopListening()
                    }
                }
            }
            .onChange(of: authService.currentUser?.uid) { _, newUid in
                if let uid = newUid {
                    userDocumentService.startListening(userId: uid)
                } else {
                    userDocumentService.stopListening()
                }
            }
        }
    }

    // MARK: - Startup Views

    private var startupView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .controlSize(.large)
            Text(Strings.Common.loading)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }

    private func bannedView(result: SecurityStartupResult) -> some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.error)

            Text(Strings.Common.accessRestricted)
                .font(Typography.h4)

            Text(result.message ?? Strings.Common.accessRestrictedMessage)
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}
