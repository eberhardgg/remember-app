import Foundation
import SwiftData

protocol ReviewServiceProtocol {
    func getDueCount() -> Int
    func getReviewQueue(limit: Int) -> [Person]
    func updateReviewState(for person: Person, gotIt: Bool)
}

final class ReviewService: ReviewServiceProtocol {
    private let modelContext: ModelContext

    // SM-2 algorithm constants
    private let minEaseFactor: Double = 1.3
    private let maxEaseFactor: Double = 3.0
    private let easeIncrement: Double = 0.1
    private let easeDecrement: Double = 0.2

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Returns count of people due for review
    func getDueCount() -> Int {
        let now = Date()
        let predicate = #Predicate<Person> { person in
            person.nextDueAt <= now
        }

        var descriptor = FetchDescriptor<Person>(predicate: predicate)
        descriptor.propertiesToFetch = []

        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            return 0
        }
    }

    /// Returns review queue: due items first, then near-due items
    func getReviewQueue(limit: Int = 5) -> [Person] {
        let now = Date()

        // Fetch due items (sorted by most overdue first)
        let duePredicate = #Predicate<Person> { person in
            person.nextDueAt <= now
        }
        var dueDescriptor = FetchDescriptor<Person>(
            predicate: duePredicate,
            sortBy: [SortDescriptor(\.nextDueAt, order: .forward)]
        )
        dueDescriptor.fetchLimit = limit

        do {
            var queue = try modelContext.fetch(dueDescriptor)

            // If we have room, add some near-due items
            if queue.count < limit {
                let remaining = limit - queue.count
                let dueIds = Set(queue.map { $0.id })

                // Get items due within next 2 days that aren't already in queue
                let twoDaysFromNow = Calendar.current.date(byAdding: .day, value: 2, to: now)!
                let nearDuePredicate = #Predicate<Person> { person in
                    person.nextDueAt > now && person.nextDueAt <= twoDaysFromNow
                }
                var nearDueDescriptor = FetchDescriptor<Person>(
                    predicate: nearDuePredicate,
                    sortBy: [SortDescriptor(\.nextDueAt, order: .forward)]
                )
                nearDueDescriptor.fetchLimit = remaining

                let nearDue = try modelContext.fetch(nearDueDescriptor)
                    .filter { !dueIds.contains($0.id) }

                queue.append(contentsOf: nearDue.prefix(remaining))
            }

            return queue
        } catch {
            print("Failed to fetch review queue: \(error)")
            return []
        }
    }

    /// Updates review state using SM-2 algorithm
    func updateReviewState(for person: Person, gotIt: Bool) {
        person.lastReviewedAt = Date()

        if gotIt {
            // Success: increase interval and ease
            let newInterval = Double(person.intervalDays) * person.easeFactor
            person.intervalDays = max(1, Int(newInterval.rounded()))
            person.easeFactor = min(maxEaseFactor, person.easeFactor + easeIncrement)
        } else {
            // Failure: reset interval, decrease ease
            person.intervalDays = 1
            person.easeFactor = max(minEaseFactor, person.easeFactor - easeDecrement)
        }

        // Calculate next due date
        person.nextDueAt = Calendar.current.date(
            byAdding: .day,
            value: person.intervalDays,
            to: Date()
        ) ?? Date()

        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to save review state: \(error)")
        }
    }
}
