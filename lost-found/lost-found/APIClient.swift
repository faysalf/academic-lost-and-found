import Foundation

// MARK: - Configuration
private let serverBaseURL = "http://127.0.0.1:8000/"
private let apiBaseURL    = "\(serverBaseURL)/api"

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidURL
    case serverUnreachable
    case invalidCredentials
    case httpError(Int, String?)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .serverUnreachable:
            return "Cannot reach the server. Make sure your phone and Mac are on the same Wi-Fi and the server is running."
        case .invalidCredentials:
            return "Incorrect phone number or password. Please try again."
        case .httpError(let code, let message):
            return message ?? "The server returned an error (code \(code))."
        case .decodingError:
            return "Received an unexpected response from the server."
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Client

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 15
        return URLSession(configuration: cfg)
    }()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: Auth

    func login(phone: String, password: String) async throws -> User {
        try await post(path: "/auth/login/", body: LoginRequest(phone: phone, password: password))
    }

    func signUp(phone: String, name: String, address: String, password: String, password2: String) async throws {
        let body = SignUpRequest(phone: phone, name: name, address: address, password: password, password2: password2)
        try await postVoid(path: "/auth/signup/", body: body)
    }

    // MARK: Posts

    func fetchPosts(type: PostType? = nil) async throws -> [Post] {
        var path = "/posts/"
        if let t = type { path += "?type=\(t.rawValue)" }
        return try await get(path: path)
    }

    func fetchPost(id: Int) async throws -> Post {
        try await get(path: "/posts/\(id)/")
    }

    func createPost(itemName: String, description: String, type: PostType, userId: Int) async throws -> Post {
        let body = CreatePostRequest(
            itemName: itemName, description: description,
            type: type.rawValue, isOwnerGiven: false, user: userId
        )
        return try await post(path: "/posts/", body: body)
    }

    func updatePost(id: Int, req: UpdatePostRequest) async throws -> Post {
        try await patch(path: "/posts/\(id)/", body: req)
    }

    func deletePost(id: Int) async throws {
        try await deleteRequest(path: "/posts/\(id)/")
    }

    // MARK: - Generic HTTP

    private func get<T: Decodable>(path: String) async throws -> T {
        let req = try buildRequest(path: path, method: "GET")
        return try await perform(req)
    }

    private func post<B: Encodable, T: Decodable>(path: String, body: B) async throws -> T {
        var req = try buildRequest(path: path, method: "POST")
        req.httpBody = try encoder.encode(body)
        return try await perform(req)
    }

    private func postVoid<B: Encodable>(path: String, body: B) async throws {
        var req = try buildRequest(path: path, method: "POST")
        req.httpBody = try encoder.encode(body)
        try await performVoid(req)
    }

    private func patch<B: Encodable, T: Decodable>(path: String, body: B) async throws -> T {
        var req = try buildRequest(path: path, method: "PATCH")
        req.httpBody = try encoder.encode(body)
        return try await perform(req)
    }

    private func deleteRequest(path: String) async throws {
        let req = try buildRequest(path: path, method: "DELETE")
        try await performVoid(req)
    }

    private func buildRequest(path: String, method: String) throws -> URLRequest {
        guard let url = URL(string: apiBaseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return req
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data = try await execute(request)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func performVoid(_ request: URLRequest) async throws {
        _ = try await execute(request)
    }

    @discardableResult
    private func execute(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.networkError(URLError(.badServerResponse))
            }
            if http.statusCode == 401 || http.statusCode == 403 {
                throw APIError.invalidCredentials
            }
            if http.statusCode >= 400 {
                throw APIError.httpError(http.statusCode, parseErrorMessage(from: data))
            }
            return data
        } catch let e as APIError {
            throw e
        } catch let e as URLError {
            switch e.code {
            case .notConnectedToInternet, .timedOut, .cannotConnectToHost,
                 .networkConnectionLost, .cannotFindHost:
                throw APIError.serverUnreachable
            default:
                throw APIError.networkError(e)
            }
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let detail = json["detail"] as? String { return detail }
        if let errors = json["non_field_errors"] as? [String], let first = errors.first { return first }
        let messages = json.compactMap { key, value -> String? in
            if let arr = value as? [String], let first = arr.first {
                return "\(key.replacingOccurrences(of: "_", with: " ").capitalized): \(first)"
            }
            return nil
        }
        return messages.isEmpty ? nil : messages.joined(separator: "\n")
    }
}
