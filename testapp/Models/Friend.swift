import Foundation

public struct Friend: Identifiable, Hashable, Codable {
    public var id = UUID() // or you may have an existing unique identifier
    var name: String
    var share: Double // Assuming this field exists for the custom split functionality
    var balance: Double = 0.0
}
