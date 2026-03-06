import LocalAuthentication
import SwiftUI

/// Manages parent-only access via a 4-digit PIN and/or Face ID / Touch ID.
///
/// Parent settings (API key, model, debug mode) are behind this gate.
/// The gate is unlocked for the duration of the settings session;
/// navigating away re-locks it.
@Observable
final class ParentGate {

    var isUnlocked = false

    private let settings: AppSettings

    init(settings: AppSettings = .shared) {
        self.settings = settings
    }

    /// Attempt to unlock using biometrics (Face ID / Touch ID).
    /// Falls back to PIN entry if biometrics fail or are unavailable.
    func unlockWithBiometrics() async -> Bool {
        guard settings.isBiometricEnabled else { return false }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock parent settings"
            )
            if success { isUnlocked = true }
            return success
        } catch {
            return false
        }
    }

    /// Attempt to unlock with a 4-digit PIN.
    func unlockWithPIN(_ enteredPIN: String) async -> Bool {
        guard let storedPIN = await KeychainService.shared.retrievePIN() else {
            // No PIN set — should not happen if PIN is enabled,
            // but allow through to avoid locking out the parent.
            isUnlocked = true
            return true
        }
        let match = enteredPIN == storedPIN
        if match { isUnlocked = true }
        return match
    }

    /// Set or update the parent PIN.
    func setPIN(_ pin: String) async throws {
        try await KeychainService.shared.savePIN(pin)
        settings.isParentPINEnabled = true
    }

    /// Remove the parent PIN.
    func removePIN() async throws {
        try await KeychainService.shared.deletePIN()
        settings.isParentPINEnabled = false
        settings.isBiometricEnabled = false
    }

    /// Lock the gate (call when leaving settings).
    func lock() {
        isUnlocked = false
    }
}
