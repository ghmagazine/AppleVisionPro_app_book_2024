import Foundation

final class TranslateRepository {
    private let basePath: String = "Your API Path"
    private var currentTask: Task<String, Error>?
    
    public func request(text: String, source: String, target: String) async throws -> String {
        currentTask?.cancel()
        currentTask = Task {
            guard let url = URL(string: basePath + "?text=\(text)&source=\(source)&target=\(target)") else {
                throw NSError(domain: "URL error", code: -1)
            }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "GET"
            
            guard let (data, urlResponse) = try? await URLSession.shared.data(for: urlRequest) else {
                throw NSError(domain: "URLSession error", code: -1)
            }
            guard let httpStatus = urlResponse as? HTTPURLResponse else {
                throw NSError(domain: "HTTPURLResponse error", code: -1)
            }
            guard let response = String(data: data, encoding: .utf8) else {
                throw NSError(domain: "\(httpStatus.statusCode)", code: -1)
            }
            return response
        }
        return try await currentTask!.value
    }
    
    public func cancelAllRequests() {
        currentTask?.cancel()
    }
}
