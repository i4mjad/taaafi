import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore

/// Manages device ID generation and user device tracking in Firestore
/// Ported from: apps/mobile/lib/core/services/device_tracking_service.dart
@Observable
@MainActor
final class DeviceTrackingService {

    private static let deviceIdKey = "device_id"

    var deviceId: String = ""

    private let db = Firestore.firestore()
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        deviceId = loadOrGenerateDeviceId()
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    /// Set up auth state listener to auto-update device tracking on login
    func startListeningToAuthState() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self, let user else { return }
            Task { @MainActor in
                try? await self.updateUserDeviceIds(userId: user.uid)
            }
        }
    }

    // MARK: - Device ID

    private func loadOrGenerateDeviceId() -> String {
        if let stored = UserDefaults.standard.string(forKey: Self.deviceIdKey) {
            return stored
        }

        let newId = UIDevice.current.identifierForVendor?.uuidString ?? "ios_\(UUID().uuidString)"
        UserDefaults.standard.set(newId, forKey: Self.deviceIdKey)
        return newId
    }

    // MARK: - Firestore Device Tracking

    /// Add this device ID to the user's devicesIds array in Firestore
    func updateUserDeviceIds(userId: String) async throws {
        let userRef = db.collection("users").document(userId)
        let doc = try await userRef.getDocument()

        if !doc.exists {
            try await userRef.setData([
                "devicesIds": [deviceId],
                "lastDeviceUpdate": FieldValue.serverTimestamp(),
            ], merge: true)
            return
        }

        let currentIds = (doc.data()?["devicesIds"] as? [String]) ?? []

        guard !currentIds.contains(deviceId) else { return }

        // Add device via arrayUnion
        try await userRef.updateData([
            "devicesIds": FieldValue.arrayUnion([deviceId]),
            "lastDeviceUpdate": FieldValue.serverTimestamp(),
        ])

        // Trim to max 10 device IDs
        let updatedIds = currentIds + [deviceId]
        if updatedIds.count > 10 {
            let toKeep = Array(updatedIds.suffix(10))
            try await userRef.updateData([
                "devicesIds": toKeep,
                "lastDeviceUpdate": FieldValue.serverTimestamp(),
            ])
        }
    }

    /// Get current user's device IDs from Firestore
    func getCurrentUserDeviceIds() async -> [String] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        return await getUserDeviceIds(userId: uid)
    }

    /// Get device IDs for a specific user
    func getUserDeviceIds(userId: String) async -> [String] {
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            return (doc.data()?["devicesIds"] as? [String]) ?? []
        } catch {
            return []
        }
    }

    /// Remove a device ID from a user's profile
    func removeDeviceIdFromUser(userId: String, deviceId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "devicesIds": FieldValue.arrayRemove([deviceId]),
            "lastDeviceUpdate": FieldValue.serverTimestamp(),
        ])
    }
}
