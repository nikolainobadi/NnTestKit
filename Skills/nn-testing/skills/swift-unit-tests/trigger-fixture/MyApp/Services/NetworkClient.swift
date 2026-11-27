import Foundation

protocol HTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPTransport { }

enum NetworkError: Error, Equatable {
    case badStatus(Int)
    case invalidResponse
}

final class NetworkClient {
    private let baseURL: URL
    private let transport: HTTPTransport

    init(baseURL: URL, transport: HTTPTransport) {
        self.baseURL = baseURL
        self.transport = transport
    }

    func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        let request = URLRequest(url: baseURL.appendingPathComponent(path))
        let (data, response) = try await transport.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw NetworkError.badStatus(http.statusCode) }

        return try JSONDecoder().decode(T.self, from: data)
    }
}
