import Foundation
import SwiftData

@Model
final class CartItemEntity {
    @Attribute(.unique) var productID: String
    var quantity: Int
    var name: String
    var price: String
    var imageURL: String?
    var weight: Int?

    init(
        productID: String,
        quantity: Int,
        name: String,
        price: String,
        imageURL: String?,
        weight: Int?
    ) {
        self.productID = productID
        self.quantity = quantity
        self.name = name
        self.price = price
        self.imageURL = imageURL
        self.weight = weight
    }
}
