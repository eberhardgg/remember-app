import Foundation

extension Date {
    /// Returns a relative description like "Today", "Tomorrow", "In 3 days", "2 days ago"
    var relativeDescription: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInTomorrow(self) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        }

        let days = calendar.dateComponents([.day], from: now, to: self).day ?? 0

        if days > 0 {
            return "In \(days) \(days == 1 ? "day" : "days")"
        } else {
            let absDays = abs(days)
            return "\(absDays) \(absDays == 1 ? "day" : "days") ago"
        }
    }
}
