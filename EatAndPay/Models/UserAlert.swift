import Foundation

struct UserAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String

    static func error(_ error: any Error, title: String = "Что-то пошло не так") -> UserAlert {
        UserAlert(title: title, message: error.localizedDescription)
    }
}
