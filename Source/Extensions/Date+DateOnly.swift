import Foundation

extension Date {
    public func dateOnly() -> Date {
        return Date(year: year, month: month, day: day)
    }
}
