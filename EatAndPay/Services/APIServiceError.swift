import Foundation

enum APIServiceError: LocalizedError {
    case unauthorized
    case notFound
    case invalidData
    case rejected
    case unexpectedStatusCode(Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Сессия истекла. Авторизуйся и попробуй снова."
        case .notFound:
            return "Запрошенные данные не найдены."
        case .invalidData:
            return "Сервер вернул некорректные данные."
        case .rejected:
            return "Сервер не принял данные. Проверь заполненные поля."
        case .unexpectedStatusCode(let statusCode):
            return "Сервер вернул ошибку \(statusCode). Попробуй ещё раз."
        }
    }
}
