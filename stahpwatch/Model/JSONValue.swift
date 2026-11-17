import Foundation

/// Any JSON value. Used to carry saved data this version doesn't understand, so that saving
/// writes it back unchanged instead of dropping it. That keeps a newer version's settings
/// safe when an older version is installed over it.
enum JSONValue: Codable, Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }

    /// Converts any Codable value to its JSON form.
    init<T: Encodable>(encoding value: T) throws {
        self = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))
    }

    /// Decodes a Codable value from this JSON.
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try JSONDecoder().decode(type, from: JSONEncoder().encode(self))
    }
}

/// A coding key for any field name, used to find the fields a type doesn't know.
struct AnyCodingKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init(_ string: String) { stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}

extension KeyedDecodingContainer where Key == AnyCodingKey {
    /// Every field except the known ones, kept as raw JSON.
    func unknownFields(besides known: Set<String>) throws -> [String: JSONValue] {
        var extras: [String: JSONValue] = [:]
        for key in allKeys where !known.contains(key.stringValue) {
            extras[key.stringValue] = try decode(JSONValue.self, forKey: key)
        }
        return extras
    }
}

extension KeyedEncodingContainer where Key == AnyCodingKey {
    mutating func encodeUnknownFields(_ extras: [String: JSONValue]) throws {
        for (name, value) in extras {
            try encode(value, forKey: AnyCodingKey(name))
        }
    }
}
