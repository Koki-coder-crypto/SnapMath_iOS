import Foundation
import UIKit

// MARK: - Data Models
struct MathSolution: Codable, Identifiable {
    var id = UUID()
    let problem: String
    let steps: [String]
    let answer: String
    let explanation: String

    enum CodingKeys: String, CodingKey {
        case problem, steps, answer, explanation
    }
}

struct MathHistoryItem: Identifiable, Codable {
    var id = UUID()
    let problemText: String
    let answer: String
    let stepsCount: Int
    let solvedAt: Date
    var thumbnailData: Data?
}

// MARK: - History Store
class MathHistoryStore: ObservableObject {
    @Published var items: [MathHistoryItem] = []
    private let saveKey = "math_history_v1"

    init() { load() }

    func add(_ solution: MathSolution, image: UIImage?) {
        let item = MathHistoryItem(
            problemText: solution.problem,
            answer:      solution.answer,
            stepsCount:  solution.steps.count,
            solvedAt:    Date(),
            thumbnailData: image?.jpegData(compressionQuality: 0.3)
        )
        items.insert(item, at: 0)
        if items.count > 100 { items = Array(items.prefix(100)) }
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([MathHistoryItem].self, from: data) {
            items = decoded
        }
    }
}
