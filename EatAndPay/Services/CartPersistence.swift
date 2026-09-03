import Foundation
import SwiftData

@MainActor
protocol CartPersistence {
    func load() throws -> LocalCartSnapshot
    func save(cart: Cart, products: [Product]) throws
    func clear() throws
}

@MainActor
final class SwiftDataCartPersistence: CartPersistence {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func load() throws -> LocalCartSnapshot {
        let entities = try context.fetch(FetchDescriptor<CartItemEntity>())
        let quantities = Dictionary(uniqueKeysWithValues: entities.map { ($0.productID, $0.quantity) })
        let products = entities.compactMap(Self.product)
        return LocalCartSnapshot(cart: Cart(quantities: quantities), products: products)
    }

    func save(cart: Cart, products: [Product]) throws {
        let entities = try context.fetch(FetchDescriptor<CartItemEntity>())
        let existingByID = Dictionary(uniqueKeysWithValues: entities.map { ($0.productID, $0) })
        let productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })

        for entity in entities where cart.quantity(for: entity.productID) == 0 {
            context.delete(entity)
        }

        for (productID, quantity) in cart.quantities {
            if let entity = existingByID[productID] {
                entity.quantity = quantity
                if let product = productsByID[productID] {
                    Self.update(entity, with: product)
                }
            } else if let product = productsByID[productID] {
                context.insert(Self.entity(for: product, quantity: quantity))
            }
        }

        try context.save()
    }

    func clear() throws {
        try context.delete(model: CartItemEntity.self)
        try context.save()
    }

    private static func entity(for product: Product, quantity: Int) -> CartItemEntity {
        CartItemEntity(
            productID: product.id,
            quantity: quantity,
            name: product.name,
            price: NSDecimalNumber(decimal: product.price).stringValue,
            imageURL: product.imageURL?.absoluteString,
            weight: product.weight
        )
    }

    private static func update(_ entity: CartItemEntity, with product: Product) {
        entity.name = product.name
        entity.price = NSDecimalNumber(decimal: product.price).stringValue
        entity.imageURL = product.imageURL?.absoluteString
        entity.weight = product.weight
    }

    private static func product(from entity: CartItemEntity) -> Product? {
        guard let price = Decimal(string: entity.price, locale: Locale(identifier: "en_US_POSIX")) else {
            return nil
        }

        return Product(
            id: entity.productID,
            name: entity.name,
            price: price,
            imageURL: entity.imageURL.flatMap(URL.init(string:)),
            weight: entity.weight
        )
    }
}
