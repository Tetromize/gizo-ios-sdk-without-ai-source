//
//  TripCSVPhoneModel.swift
//  GizoSDK
//

import UIKit

class TripCSVPhoneModel: Codable {
    var time: String  = DateTimeUtil.stringFromDateTime(date: Date(), format: "yyyy-MM-dd HH:mm:ss.SSS").appending("Z").replacingOccurrences(of: " ", with: "T")
    var event: String = "N/A"
    var value: String = "N/A"
    
    static var csvDesc: String {
        return "Time,Event,Value"
    }
    
    var csvValue: String {
        return "\(time),\(event),\(value)"
    }
}
