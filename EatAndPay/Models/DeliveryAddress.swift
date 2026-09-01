import Foundation

struct DeliveryAddress: Identifiable, Equatable, Sendable {
    let id: String
    var addressLine: String
    var longitude: Double
    var latitude: Double
    var floor: String
    var entrance: String
    var intercomCode: String
    var comment: String
}

struct AddressDraft: Equatable, Sendable {
    var addressLine = ""
    var longitude = "37.6173"
    var latitude = "55.7558"
    var floor = ""
    var entrance = ""
    var intercomCode = ""
    var comment = ""

    init(address: DeliveryAddress? = nil) {
        guard let address else { return }
        addressLine = address.addressLine
        longitude = Self.coordinateString(address.longitude)
        latitude = Self.coordinateString(address.latitude)
        floor = address.floor
        entrance = address.entrance
        intercomCode = address.intercomCode
        comment = address.comment
    }

    var coordinates: (longitude: Double, latitude: Double)? {
        guard
            let longitude = Self.coordinate(from: longitude),
            let latitude = Self.coordinate(from: latitude),
            (-180...180).contains(longitude),
            (-90...90).contains(latitude)
        else {
            return nil
        }

        return (longitude, latitude)
    }

    var isValid: Bool {
        !addressLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && coordinates != nil
    }

    private static func coordinate(from value: String) -> Double? {
        Double(value.replacingOccurrences(of: ",", with: "."))
    }

    private static func coordinateString(_ value: Double) -> String {
        String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}
