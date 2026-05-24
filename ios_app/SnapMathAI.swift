import Foundation
import UIKit

actor SnapMathAI {
    static let shared = SnapMathAI()
    private let apiKey = Bundle.main.infoDictionary?["ANTHROPIC_API_KEY"] as? String ?? ""

    func solveMath(from image: UIImage) async throws -> MathSolution {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AIError.imageConversion
        }
        let base64 = imageData.base64EncodedString()

        let body: [String: Any] = [
            "model": "claude-opus-4-5",
            "max_tokens": 2000,
            "messages": [[
                "role": "user",
                "content": [
                    [
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": base64
                        ]
                    ],
                    [
                        "type": "text",
                        "text": """
                        You are a math tutor. Solve the math problem shown in this image step by step.
                        Return ONLY valid JSON in this exact format:
                        {"problem": "the problem as text", "steps": ["Step 1: ...", "Step 2: ...", "Step 3: ..."], "answer": "final answer", "explanation": "brief explanation of the method used"}
                        Be thorough with steps. Show all work clearly.
                        """
                    ]
                ]
            ]]
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIError.apiError
        }

        let resp = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        guard let text = resp.content.first?.text else { throw AIError.parseError }

        // Extract JSON from response (might be wrapped in markdown)
        let jsonString = extractJSON(from: text)
        guard let jsonData = jsonString.data(using: .utf8),
              let solution = try? JSONDecoder().decode(MathSolution.self, from: jsonData)
        else { throw AIError.parseError }

        return solution
    }

    private func extractJSON(from text: String) -> String {
        if let start = text.range(of: "{"), let end = text.range(of: "}", options: .backwards) {
            return String(text[start.lowerBound...end.upperBound])
        }
        return text
    }

    enum AIError: LocalizedError {
        case imageConversion, apiError, parseError

        var errorDescription: String? {
            switch self {
            case .imageConversion: return "Could not process image"
            case .apiError:        return "AI service unavailable"
            case .parseError:      return "Could not parse response"
            }
        }
    }

    struct AnthropicResponse: Codable {
        struct Content: Codable { let text: String }
        let content: [Content]
    }
}
