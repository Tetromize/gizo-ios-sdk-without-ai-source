//
//  TripCSVGPSModel.swift
//  Gizo
//
//  Created by Hepburn on 2023/9/22.
//

import Foundation

struct TripCSVGPSModel: Codable {
    var gpsTime: String  = DateTimeUtil.stringFromDateTime(date: Date(), format: "yyyy-MM-dd HH:mm:ss.SSS").appending("Z").replacingOccurrences(of: " ", with: "T")
    var altitude: Double?
    var latitude: Double?
    var longitude: Double?
    var speed: String = "0"
    var speedLimit: String = "N/A"
    var climb: String = "0.0"
    var course: Double?
    var EPX: String = "N/A"
    var EPY: String = "N/A"
    var EPV: String = "N/A"
    var EPS: String = "N/A"
    var EPC: String = "N/A"
    var EPD: String = "N/A"
    
    static var csvDesc: String {
        return "GPSTime,Altitude,Latitude,Longitude,Speed,SpeedLimit,Climb,Course,EPX,EPY,EPV,EPS,EPC,EPD"
    }

    var csvValue: String {
        let altitudeText = NSString.init(format: "%.1f", self.altitude!)
        let latitudeText = NSString.init(format: "%.6f", self.latitude!)
        let longitudeText = NSString.init(format: "%.6f", self.longitude!)
        let courseText = NSString.init(format: "%.6f", self.course!)
        return "\(self.gpsTime),\(altitudeText),\(latitudeText),\(longitudeText),\(self.speed),\(self.speedLimit),\(self.climb),\(courseText),\(self.EPX),\(self.EPY),\(self.EPV),\(self.EPS),\(self.EPC),\(self.EPD)"
    }
}
