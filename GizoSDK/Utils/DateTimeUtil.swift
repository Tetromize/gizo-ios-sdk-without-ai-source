//
//  DateTimeUtil.swift
//  Gizo
//
//  Created by Hepburn on 2023/9/8.
//

import Foundation

class DateTimeUtil {
    static public func dateTimeFromString(_ timeStr: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return dateFormatter.date(from: timeStr)
    }
    
    static public func dateTimeFromString(_ timeStr: String, format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: timeStr)
    }
    
    static public func stringFromDateTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    static public func stringFromDateTime(date: Date, format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    
    static public func dateFromString(_ timeStr: String) -> String {
        let timeStr1: String = timeStr.replacingOccurrences(of: "T", with: " ")
        let date: Date? = dateTimeFromString(timeStr1)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date!)
    }
    
    static public func timeFromString(_ timeStr: String) -> String {
        let date: Date? = dateTimeFromString(timeStr)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter.string(from: date!)
    }
    
    static private func formatNumber(_ value: String) -> String {
        var value1 = value
        let subArray = value.split(separator: ".")
        if (subArray.count == 2) {
            value1 = "\(subArray.first!)"
        }
        if let myInteger = Int(value1) {
            let myNumber = NSNumber(value:myInteger)
            return myNumber.stringValue
        }
        return ""
    }
    
    static public func durationFormat(_ timeText: String) -> String {
        let subArray = timeText.split(separator: ":")
        var array: [String] = []
        subArray.forEach { (item) in
            array.append("\(item)")
        }
        if (array.count == 3) {
            return formatNumber(array[0])+"h "+formatNumber(array[1])+"m "+formatNumber(array[2])+"s"
        }
        return ""
    }
    
    static public func shortDate(_ timeStr: String) -> String {
        let timeStr1: String = timeStr.replacingOccurrences(of: "T", with: " ")
        let date: Date? = dateTimeFromString(timeStr1)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date!)
    }
    
    static public func shortTime(_ timeStr: String) -> String {
        let timeStr1: String = timeStr.replacingOccurrences(of: "T", with: " ")
        let date: Date? = dateTimeFromString(timeStr1)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        let str = dateFormatter.string(from: date!)
        return str.replacingOccurrences(of: " ", with: "").lowercased()
    }
}
