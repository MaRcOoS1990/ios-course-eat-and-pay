import Foundation

actor CartStore {
    private let service: any CartService

    private var cart = Cart()
    private var products: [Product] = []
    private var deliveryTime = 0
    private var deliveryPrice = Decimal.zero

    private var isOperationInProgress = false
    private var operationWaiters: [CheckedContinuation<Void, Never>] = []

    init(service: any CartService) {
        self.service = service
    }

    func restore(_ localSnapshot: LocalCartSnapshot) async -> CartSnapshot {
        await acquireOperation()
        defer { releaseOperation() }

        cart = localSnapshot.cart
        mergeProducts(localSnapshot.products)
        deliveryTime = 0
        deliveryPrice = .zero
        return snapshot()
    }

    func synchronize() async throws -> CartSnapshot {
        await acquireOperation()
        defer { releaseOperation() }

        try Task.checkCancellation()
        let serverSnapshot = try await service.loadCart()
        cart = serverSnapshot.cart
        mergeProducts(serverSnapshot.products)
        deliveryTime = serverSnapshot.deliveryTime
        deliveryPrice = serverSnapshot.deliveryPrice
        return snapshot()
    }

    func add(_ product: Product) async throws -> CartSnapshot {
        await acquireOperation()
        defer { releaseOperation() }

        try Task.checkCancellation()
        try await service.addProduct(id: product.id)
        cart.add(product.id)
        mergeProducts([product])
        return snapshot()
    }

    func remove(_ product: Product) async throws -> CartSnapshot {
        await acquireOperation()
        defer { releaseOperation() }

        guard cart.quantity(for: product.id) > 0 else {
            return snapshot()
        }

        try Task.checkCancellation()
        try await service.removeProduct(id: product.id)
        cart.remove(product.id)
        mergeProducts([product])
        return snapshot()
    }

    func clear() async -> CartSnapshot {
        await acquireOperation()
        defer { releaseOperation() }

        cart.removeAll()
        deliveryTime = 0
        deliveryPrice = .zero
        return snapshot()
    }

    func updateProducts(_ updatedProducts: [Product]) {
        mergeProducts(updatedProducts)
    }

    func currentSnapshot() -> CartSnapshot {
        snapshot()
    }

    private func mergeProducts(_ updatedProducts: [Product]) {
        let updatedIDs = Set(updatedProducts.map(\.id))
        products.removeAll { updatedIDs.contains($0.id) }
        products.append(contentsOf: updatedProducts)
    }

    private func snapshot() -> CartSnapshot {
        let orderPrice = cart.totalPrice(for: products)
        return CartSnapshot(
            cart: cart,
            products: products,
            deliveryTime: deliveryTime,
            orderPrice: orderPrice,
            deliveryPrice: deliveryPrice,
            totalPrice: orderPrice + deliveryPrice
        )
    }

    private func acquireOperation() async {
        if !isOperationInProgress {
            isOperationInProgress = true
            return
        }

        await withCheckedContinuation { continuation in
            operationWaiters.append(continuation)
        }
    }

    private func releaseOperation() {
        guard !operationWaiters.isEmpty else {
            isOperationInProgress = false
            return
        }

        operationWaiters.removeFirst().resume()
    }
}
