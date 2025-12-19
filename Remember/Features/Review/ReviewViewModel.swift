import Foundation
import Observation

@Observable
final class ReviewViewModel {
    private let reviewService: ReviewServiceProtocol
    private var queue: [Person] = []
    private let singlePerson: Person?

    var currentIndex: Int = 0
    var isRevealed: Bool = false
    var isComplete: Bool = false

    var currentPerson: Person? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    var totalCount: Int {
        queue.count
    }

    init(reviewService: ReviewServiceProtocol, singlePerson: Person? = nil) {
        self.reviewService = reviewService
        self.singlePerson = singlePerson
    }

    func loadQueue() {
        if let person = singlePerson {
            // Single person quiz mode
            queue = [person]
        } else {
            // Normal review queue
            queue = reviewService.getReviewQueue(limit: 5)
        }

        if queue.isEmpty {
            isComplete = true
        }
    }

    func reveal() {
        isRevealed = true
    }

    func markGotIt() {
        guard let person = currentPerson else { return }
        reviewService.updateReviewState(for: person, gotIt: true)
        advance()
    }

    func markMissed() {
        guard let person = currentPerson else { return }
        reviewService.updateReviewState(for: person, gotIt: false)
        advance()
    }

    private func advance() {
        isRevealed = false
        currentIndex += 1

        if currentIndex >= queue.count {
            isComplete = true
        }
    }
}
