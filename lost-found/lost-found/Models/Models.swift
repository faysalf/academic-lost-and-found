import Foundation

// MARK: - Domain Models

struct User: Codable, Equatable {
    let id: Int
    let phone: String
    let name: String
}

struct Post: Codable, Identifiable {
    let id: Int
    let itemName: String
    let description: String
    let type: String          // "Lost" or "Found"
    let isOwnerGiven: Bool
    let user: Int
    let userName: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case itemName    = "item_name"
        case description
        case type
        case isOwnerGiven = "is_owner_given"
        case user
        case userName    = "user_name"
        case createdAt   = "created_at"
    }

    var postType: PostType { PostType(rawValue: type) ?? .lost }

    var formattedDate: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = iso.date(from: createdAt)
        if date == nil {
            iso.formatOptions = [.withInternetDateTime]
            date = iso.date(from: createdAt)
        }
        guard let d = date else { return createdAt }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: d)
    }
}

enum PostType: String, CaseIterable {
    case lost  = "Lost"
    case found = "Found"

    var label: String { rawValue }

    var icon: String {
        switch self {
        case .lost:  return "magnifyingglass"
        case .found: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Request Bodies

struct LoginRequest: Encodable {
    let phone: String
    let password: String
}

struct SignUpRequest: Encodable {
    let phone: String
    let name: String
    let address: String
    let password: String
    let password2: String
}

struct CreatePostRequest: Encodable {
    let itemName: String
    let description: String
    let type: String
    let isOwnerGiven: Bool
    let user: Int

    enum CodingKeys: String, CodingKey {
        case itemName    = "item_name"
        case description
        case type
        case isOwnerGiven = "is_owner_given"
        case user
    }
}

struct UpdatePostRequest: Encodable {
    var itemName: String?
    var description: String?
    var type: String?
    var isOwnerGiven: Bool?

    enum CodingKeys: String, CodingKey {
        case itemName    = "item_name"
        case description
        case type
        case isOwnerGiven = "is_owner_given"
    }
}
