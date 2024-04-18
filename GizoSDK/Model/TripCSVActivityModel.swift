//
//  TripCSVActivityModel.swift
//  Gizo
//
//  Created by Hepburn on 2023/10/24.
//

import UIKit

class TripCSVActivityModel: Codable {
    var time: String  = DateTimeUtil.stringFromDateTime(date: Date(), format: "yyyy-MM-dd HH:mm:ss.SSS").appending("Z").replacingOccurrences(of: " ", with: "T")
    var stopped: String = "N/A"
    var started: String = "N/A"
    
    static var csvDesc: String {
        return "Time,Stopped,Started"
    }
    
    var csvValue: String {
        return "\(time),\(stopped),\(started)"
    }
}
