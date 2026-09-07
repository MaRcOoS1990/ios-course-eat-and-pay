import Foundation

struct UserProfile: Equatable, Sendable {
    let name: String
    let phone: String
    let birthday: String
    let imageURL: URL?

    var draft: UserProfileDraft {
        UserProfileDraft(
            name: name,
            birthday: birthday,
            imageURI: imageURL?.absoluteString ?? ""
        )
    }
}

struct UserProfileDraft: Equatable, Sendable {
    var name: String
    var birthday: String
    var imageURI: String

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedBirthday: String {
        birthday.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedImageURI: String {
        imageURI.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        !trimmedName.isEmpty
            && Self.isValidBirthday(trimmedBirthday)
            && Self.isValidImageURI(trimmedImageURI)
    }

    private static func isValidBirthday(_ value: String) -> Bool {
        guard value.range(
            of: #"^\d{2}\.\d{2}\.\d{4}$"#,
            options: .regularExpression
        ) != nil else {
            return false
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.isLenient = false
        return formatter.date(from: value) != nil
    }

    private static func isValidImageURI(_ value: String) -> Bool {
        guard
            let components = URLComponents(string: value),
            let scheme = components.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            components.host?.isEmpty == false,
            let url = components.url
        else {
            return false
        }

        return url.pathExtension.lowercased() == "jxl"
    }
}
