import Foundation

enum ReviewSort: String, CaseIterable, Identifiable, Sendable {
    case newest
    case oldest
    case highestRating
    case lowestRating

    var id: Self { self }

    var title: String {
        switch self {
        case .newest:
            "Сначала новые"
        case .oldest:
            "Сначала старые"
        case .highestRating:
            "С высокой оценкой"
        case .lowestRating:
            "С низкой оценкой"
        }
    }

    func sort(_ reviews: [Review]) -> [Review] {
        reviews.sorted { lhs, rhs in
            switch self {
            case .newest:
                lhs.createdAt > rhs.createdAt
            case .oldest:
                lhs.createdAt < rhs.createdAt
            case .highestRating:
                lhs.rating == rhs.rating
                    ? lhs.createdAt > rhs.createdAt
                    : lhs.rating > rhs.rating
            case .lowestRating:
                lhs.rating == rhs.rating
                    ? lhs.createdAt > rhs.createdAt
                    : lhs.rating < rhs.rating
            }
        }
    }
}
