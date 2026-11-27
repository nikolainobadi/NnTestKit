import Foundation

final class LoginViewModel {
    var email = ""
    var password = ""

    var canSubmit: Bool {
        return email.contains("@") && password.count >= 8
    }
}
