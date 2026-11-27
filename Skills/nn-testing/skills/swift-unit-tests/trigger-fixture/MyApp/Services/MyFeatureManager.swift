import Foundation

protocol FeatureFlagStore {
    func isEnabled(_ key: String) -> Bool
    func setEnabled(_ key: String, _ enabled: Bool)
}

final class MyFeatureManager {
    private let store: FeatureFlagStore
    private let defaultFlags: Set<String>

    init(store: FeatureFlagStore, defaultFlags: Set<String>) {
        self.store = store
        self.defaultFlags = defaultFlags
    }

    func isOn(_ key: String) -> Bool {
        return store.isEnabled(key) || defaultFlags.contains(key)
    }

    func toggle(_ key: String) {
        store.setEnabled(key, !isOn(key))
    }
}
