import Foundation

/// The learner's persisted progress, shared across the app.
///
/// Owns the two on-disk stores (`LearnerProfileStore`, `SessionHistoryStore`),
/// hands them to `SessionManager` so completed sessions are written, and
/// republishes what they hold so SwiftUI views see progress update.
///
/// Views read ``profile`` and ``recentSessions``; nothing else touches the
/// stores directly.
@MainActor
@Observable
final class LearnerState {
    /// The profile as last loaded from disk.
    private(set) var profile: LearnerProfile = .createDefault()

    /// The most recent completed sessions, newest first.
    private(set) var recentSessions: [SessionSummary] = []

    /// Whether the first load from disk has finished.
    private(set) var isLoaded = false

    private var profileStore: LearnerProfileStore?
    private var historyStore: SessionHistoryStore?

    /// How many sessions the dashboard shows without opening the full history.
    static let recentSessionCount = 5

    /// Open the stores, wire them into the session manager, and load progress.
    ///
    /// Safe to call more than once — the stores are opened only on the first call.
    func start(sessionManager: SessionManager) async {
        if profileStore == nil {
            profileStore = await LearnerProfileStore()
        }
        if historyStore == nil {
            historyStore = await SessionHistoryStore()
        }
        sessionManager.profileStore = profileStore
        sessionManager.historyStore = historyStore
        await reload(sessionManager: sessionManager)
    }

    /// Re-read progress from disk.
    ///
    /// Waits for the write started by the most recent `endSession()` first, so a
    /// learner who finishes a session and opens the dashboard sees it counted.
    func reload(sessionManager: SessionManager? = nil) async {
        await sessionManager?.persistenceTask?.value

        if let profileStore {
            profile = await profileStore.current
        }
        if let historyStore {
            recentSessions = await historyStore.recentSessions(Self.recentSessionCount)
        }
        isLoaded = true
    }
}
