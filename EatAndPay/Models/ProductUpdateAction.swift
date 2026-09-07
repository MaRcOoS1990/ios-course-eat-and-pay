import SwiftUI

struct ProductUpdateAction: Sendable {
    private let update: @MainActor @Sendable (Product) -> Void

    init(_ update: @escaping @MainActor @Sendable (Product) -> Void) {
        self.update = update
    }

    @MainActor
    func callAsFunction(_ product: Product) {
        update(product)
    }
}

private struct ProductUpdateActionKey: EnvironmentKey {
    static let defaultValue = ProductUpdateAction { _ in }
}

extension EnvironmentValues {
    var productUpdateAction: ProductUpdateAction {
        get { self[ProductUpdateActionKey.self] }
        set { self[ProductUpdateActionKey.self] = newValue }
    }
}
