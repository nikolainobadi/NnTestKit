import Foundation

enum SyncError: Error, Equatable {
    case offline
    case serverBusy
    case unauthorized
}

protocol SyncRemote {
    func push() async throws
}

final class SyncEngine {
    private let remote: SyncRemote
    private let maxAttempts: Int

    init(remote: SyncRemote, maxAttempts: Int) {
        self.remote = remote
        self.maxAttempts = maxAttempts
    }

    func sync() async throws {
        var attempt = 0

        while true {
            attempt += 1
            do {
                try await remote.push()
                return
            } catch let error as SyncError where error != .unauthorized && attempt < maxAttempts {
                continue
            }
        }
    }
}
