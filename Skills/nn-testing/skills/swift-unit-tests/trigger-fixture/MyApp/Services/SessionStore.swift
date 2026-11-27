import Foundation

protocol TokenStorage {
    func loadToken() -> String?
    func saveToken(_ token: String?)
}

final class SessionStore {
    private let storage: TokenStorage
    private(set) var token: String?

    init(storage: TokenStorage) {
        self.storage = storage
        self.token = storage.loadToken()
    }

    var isLoggedIn: Bool {
        return token != nil
    }

    func logIn(token: String) {
        self.token = token
        storage.saveToken(token)
    }

    func logOut() {
        token = nil
        storage.saveToken(nil)
    }
}
