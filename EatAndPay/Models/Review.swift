import Foundation

struct Review: Identifiable, Sendable {
    let id: UUID
    let rating: Int
    let author: String
    let createdAt: Date
    let content: String
    let imageURLs: [URL]

    init(
        id: UUID = UUID(),
        rating: Int,
        author: String,
        createdAt: Date,
        content: String,
        imageURLs: [URL] = []
    ) {
        self.id = id
        self.rating = rating
        self.author = author
        self.createdAt = createdAt
        self.content = content
        self.imageURLs = imageURLs
    }
}

struct ReviewDraft: Sendable {
    var rating = 0
    var text = ""

    var content: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isValid: Bool { (1...5).contains(rating) && !content.isEmpty }
}
