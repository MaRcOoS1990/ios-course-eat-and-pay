import Foundation

struct CartSnapshot: Sendable {
    let cart: Cart
    let products: [Product]
    let deliveryTime: Int
    let orderPrice: Decimal
    let deliveryPrice: Decimal
    let totalPrice: Decimal
}

struct LocalCartSnapshot: Sendable {
    let cart: Cart
    let products: [Product]
}
