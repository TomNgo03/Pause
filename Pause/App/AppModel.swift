import Foundation
import SwiftUI
import Combine

@MainActor
final class AppModel: ObservableObject {
    enum Route: Equatable { case home, appSelection, plan, aiPlanner, social, profile, active, reflection, dashboard, settings }

    @Published var route: Route = .home
    @Published private(set) var activeSession: SessionDraft?
    @Published var showingError = false
    @Published var errorMessage = ""

    let preferences = PreferencesStore()
    let screenTime: ScreenTimeControlling
    let notifications = NotificationService()
    let social = SocialStore()
    let planner = AIPlanningService()
    let auth = AuthService()
    private var socialObservation: AnyCancellable?
    private var authObservation: AnyCancellable?

    init(screenTime: ScreenTimeControlling = ScreenTimeServiceFactory.make()) {
        self.screenTime = screenTime
        self.activeSession = SessionRecoveryStore.load()
        socialObservation = social.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
        authObservation = auth.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
    }

    func start(_ draft: SessionDraft) async {
        guard activeSession == nil else {
            presentError("A session is already active.")
            return
        }
        activeSession = draft
        SessionRecoveryStore.save(draft)
        do {
            try await screenTime.beginIntentionalSession(until: draft.plannedEnd)
            await notifications.scheduleSessionEnd(at: draft.plannedEnd)
            route = .active
        } catch {
            activeSession = nil
            SessionRecoveryStore.clear()
            presentError(error.localizedDescription)
        }
    }

    func extendSession(minutes: Int = 5) async {
        guard var session = activeSession else { return }
        session.plannedEnd = session.plannedEnd.addingTimeInterval(TimeInterval(minutes * 60))
        session.extensionMinutes += minutes
        activeSession = session
        SessionRecoveryStore.save(session)
        await notifications.scheduleSessionEnd(at: session.plannedEnd)
        do { try await screenTime.beginIntentionalSession(until: session.plannedEnd) }
        catch { presentError(error.localizedDescription) }
    }

    func finishSession() async {
        guard var session = activeSession else { return }
        session.actualEnd = .now
        activeSession = session
        SessionRecoveryStore.save(session)
        await screenTime.endIntentionalSession()
        notifications.cancelSessionNotifications()
        route = .reflection
    }

    func cancelSession() async {
        await screenTime.endIntentionalSession()
        notifications.cancelSessionNotifications()
        activeSession = nil
        SessionRecoveryStore.clear()
        route = .home
    }

    func completeReflection() {
        activeSession = nil
        SessionRecoveryStore.clear()
        route = .home
    }

    func clearPrivateState() async {
        await screenTime.endIntentionalSession()
        notifications.cancelSessionNotifications()
        activeSession = nil
        SessionRecoveryStore.clear()
        preferences.reset()
        route = .home
        objectWillChange.send()
    }

    func reconcileSession() async {
        guard var session = activeSession else { return }
        if session.plannedEnd <= .now {
            if session.actualEnd == nil { session.actualEnd = session.plannedEnd }
            activeSession = session
            SessionRecoveryStore.save(session)
            await screenTime.endIntentionalSession()
            route = .reflection
        } else {
            route = .active
        }
    }

    func presentError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}
