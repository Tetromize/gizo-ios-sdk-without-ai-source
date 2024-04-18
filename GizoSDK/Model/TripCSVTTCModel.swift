//
//  TripCSVTTCModel.swift
//  Gizo
//
//  Created by Hepburn on 2023/10/23.
//

import UIKit

class TripCSVTTCModel: Codable {
    var time: String  = DateTimeUtil.stringFromDateTime(date: Date(), format: "yyyy-MM-dd HH:mm:ss.SSS").appending("Z").replacingOccurrences(of: " ", with: "T")
    var speed: String = "N/A"
    var ttc: String = "None"
    var Depth: String = "N/A"
    
    static var csvDesc: String {
        return "GPSTime,Speed,TTC,Depth"
    }

    var csvValue: String {
        return "\(time),\(speed),\(ttc),\(Depth)"
    }
}
