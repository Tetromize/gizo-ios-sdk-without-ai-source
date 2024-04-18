//
//  LogActivityModel.swift
//  GizoSDK
//
//  Created by Meysam Farmani on 2/9/24.
//

import UIKit

class LogActivityModel: Codable {
    var time: String  = DateTimeUtil.stringFromDateTime(date: Date(), format: "yyyy-MM-dd HH:mm:ss.SSS").appending("Z").replacingOccurrences(of: " ", with: "T")
    var activity: String = "Unknown"
    var confidence: String = "1"
    
    static var csvDesc: String {
        return "time,activity,confidence"
    }
    
    var csvValue: String {
        return "\(time),\(activity),\(confidence)"
    }
}

