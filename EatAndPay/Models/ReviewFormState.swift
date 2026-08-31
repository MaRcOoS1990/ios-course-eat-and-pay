import Foundation
import Observation

@MainActor @Observable
final class ReviewFormState {
    var draft = ReviewDraft()
    private(set) var isSubmitting = false
    private(set) var didSubmit = false
    private(set) var errorMessage: String?

    var canSubmit: Bool { draft.isValid && !isSubmitting && !didSubmit }

    func submit(productID: Product.ID, using service: any ReviewService) async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            try await service.submit(draft, productID: productID)
            didSubmit = true
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
