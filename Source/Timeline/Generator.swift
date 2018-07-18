import Foundation

enum Generator {
    static func timeStrings24H() -> [String] {
        var numbers = [String]()
        numbers.append("00:00")
        
        for i in 1...24 {
            let i = i % 24
            var string = i < 10 ? "0" + String(i) : String(i)
            string.append(":00")
            numbers.append(string)
        }
        
        return numbers
    }
    
    static func timeStrings12H() -> [String] {
        var AMNumbers = [String]()
        
        for i in 6...11
        {
            let string = String(i)
            AMNumbers.append(string)
            AMNumbers.append(string + ":30")
        }
        
        var am = AMNumbers.map { $0 + " AM" }
        am.append("Noon")
        am.append("12:30")
        
        var PMNumbers = [String]()
        for i in 1...7
        {
            let string = String(i)
            PMNumbers.append(string)
            PMNumbers.append(string + ":30")
        }
        
        let pm = PMNumbers.map { $0 + " PM" }
        return am + pm
    }
}

