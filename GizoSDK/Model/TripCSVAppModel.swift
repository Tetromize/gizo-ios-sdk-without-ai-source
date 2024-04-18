//
//  TripCSVAppModel.swift
//  GizoSDK
//

import UIKit

class TripCSVAppModel: Codable {
    var time: String  = DateTimeUtil.stringFromDateTime(date: Date(), format: "yyyy-MM-dd HH:mm:ss.SSS").appending("Z").replacingOccurrences(of: " ", with: "T")
    var package: String = "N/A"
    var label: String = "N/A"
    var category: String = "UNDEFINED"
    var system: String = "false"
    
    static var csvDesc: String {
        return "Time,Package,Label,Category,System"
    }
    
    var csvValue: String {
        return "\(time),\(package),\(label),\(category),\(system)"
    }
}

