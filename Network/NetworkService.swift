import Foundation

// MARK: - NetworkService
final class NetworkService {
    static let shared = NetworkService()
    private let baseURL = URL(string: "https://backend.viewprotech.shop")!
    private let accessToken = "4b0ef608-b990-477c-aca8-30eb4a1881bf"

    private init() {}

    func fetchEffects(forApp appName: String, completionHandler: @escaping (Result<[Template], Error>) -> Void) {
        guard let baseUrl = URL(string: "https://testingerapp.site/api/templates") else {
            print("Failed to create base URL")
            completionHandler(.failure(NetworkError.invalidURL))
            return
        }

        var urlComponents = URLComponents(url: baseUrl, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [
            URLQueryItem(name: "appName", value: appName),
            URLQueryItem(name: "ai[]", value: "pv")
        ]

        guard let finalUrl = urlComponents?.url else {
            print("Failed to construct URL with query items")
            completionHandler(.failure(NetworkError.invalidURL))
            return
        }

        var urlRequest = URLRequest(url: finalUrl)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("Bearer rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let networkError = error {
                print("Request failed with error: \(networkError)")
                completionHandler(.failure(networkError))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completionHandler(.failure(NetworkError.invalidResponse))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("Server responded with status code: \(httpResponse.statusCode)")
                completionHandler(.failure(NetworkError.invalidResponse))
                return
            }

            guard let responseData = data else {
                print("No data received from the server")
                completionHandler(.failure(NetworkError.noData))
                return
            }

            if let rawResponse = String(data: responseData, encoding: .utf8) {
                print("Raw response data: \(rawResponse)")
            }

            do {
                let decodedResponse = try JSONDecoder().decode(TemplatesResponse.self, from: responseData)
                if decodedResponse.error {
                    completionHandler(.failure(NetworkError.apiError))
                } else {
                    if decodedResponse.data.isEmpty {
                        print("Received empty template list")
                    }
                    completionHandler(.success(decodedResponse.data))
                }
            } catch {
                print("Failed to decode response: \(error)")
                completionHandler(.failure(error))
            }
        }.resume()
    }

    func createVideoTask(imagePath: String?, userId: String, appBundle: String, prompt: String) async throws -> String {
        let url = baseURL.appendingPathComponent("/video")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(accessToken, forHTTPHeaderField: "access-token")
        request.addValue("application/json", forHTTPHeaderField: "accept")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()

        func addFormField(named name: String, value: String) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        let schema = """
        {"prompt": "\(prompt)", "image_url": "\(imagePath ?? "")", "user_id": "\(userId)", "app_bundle": "\(appBundle)"}
        """
        addFormField(named: "schema", value: schema)

        if let imagePath = imagePath, let imageData = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) {
            let fileName = URL(fileURLWithPath: imagePath).lastPathComponent
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP status-code: \(httpResponse.statusCode)")
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                throw NSError(domain: "NetworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Incorrect HTTP response"])
            }

            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            guard let videoId = json?["id"] as? String else {
                throw NSError(domain: "NetworkService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Incorrect response format"])
            }

            return videoId

        } catch {
            print("Request error: \(error.localizedDescription)")
            throw error
        }
    }

    func checkVideoTaskStatus(videoId: String) async throws -> [String: Any] {
        let url = baseURL.appendingPathComponent("/video/\(videoId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(accessToken, forHTTPHeaderField: "access-token")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP status-code: \(httpResponse.statusCode)")
        } else {
            print("Response is not HTTPResponse: \(response)")
        }

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "NetworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Incorrect HTTP response"])
        }

        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        return json ?? [:]
    }

    func downloadVideoFile(videoId: String, prompt: String) async throws -> URL {
        let url = baseURL.appendingPathComponent("/video/file/\(videoId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(accessToken, forHTTPHeaderField: "access-token")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "NetworkService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Downloading video error"])
        }

        let videoFileURL = CacheManager.shared.generatedVideosDirectory.appendingPathComponent("\(videoId).mp4")

        do {
            try data.write(to: videoFileURL)

            let videoModel = GeneratedVideo(id: videoId, prompt: prompt, isFinished: true)
            CacheManager.shared.saveGeneratedVideoModel(videoModel)

            return videoFileURL
        } catch {
            throw error
        }
    }

    func fetchEffectGenerationStatus(generationId: String?, completion: @escaping (Result<GenerationStatusData, Error>) -> Void) {
        var urlComponents = URLComponents(string: "https://testingerapp.site/api/generationStatus?format=json")
        if let generationId = generationId {
            urlComponents?.queryItems = [URLQueryItem(name: "generationId", value: generationId)]
        }

        guard let url = urlComponents?.url else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let bearerToken = "rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }

            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Response to fetchGenerationStatus:\n\(rawResponse)")
            } else {
                print("Unable to parse raw response as string")
            }

            do {
                let response = try JSONDecoder().decode(GenerationStatusResponse.self, from: data)
                completion(.success(response.data))
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }

    func generateEffect(
        templateId: String?,
        imageFilePath: String?,
        userId: String,
        appId: String,
        completion: @escaping (Result<GenerationResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "https://testingerapp.site/api/generate?format=json") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let bearerToken = "rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        if let templateId = templateId {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"templateId\"\r\n\r\n")
            body.append("\(templateId)\r\n")
        }

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"userId\"\r\n\r\n")
        body.append("\(userId)\r\n")

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"appId\"\r\n\r\n")
        body.append("\(appId)\r\n")

        if let imageFilePath = imageFilePath {
            do {
                let fileName = (imageFilePath as NSString).lastPathComponent
                let imageData = try Data(contentsOf: URL(fileURLWithPath: imageFilePath))
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(fileName)\"\r\n")
                body.append("Content-Type: image/jpeg\r\n\r\n")
                body.append(imageData)
                body.append("\r\n")
                print("Image file attached: \(fileName), size: \(imageData.count) bytes")
            } catch {
                print("Error loading image: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
        } else {
            print("No image file provided.")
        }

        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        if let bodySize = request.httpBody?.count {
            print("HTTP Body size: \(bodySize) bytes")
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response (not HTTPURLResponse)")
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            print("HTTP Response status: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                print("Server returned an error status code: \(httpResponse.statusCode)")
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            guard let data = data else {
                print("No data received from server.")
                completion(.failure(NetworkError.noData))
                return
            }

            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Response:\n\(rawResponse)")
            } else {
                print("Unable to parse raw response as string.")
            }

            do {
                let response = try JSONDecoder().decode(GenerationResponse.self, from: data)
                print("Successfully decoded response.")
                completion(.success(response))
            } catch {
                print("JSON Decoding error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

// MARK: - Data Extension
private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
