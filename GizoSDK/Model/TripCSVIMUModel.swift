//
//  TripCSVIMUModel.swift
//  Gizo
//
//  Created by Hepburn on 2023/10/22.
//

import UIKit

class TripCSVIMUModel: Codable {

    var time: String  = DateTimeUtil.stringFromDateTime(date: Date(), format: "yyyy-MM-dd HH:mm:ss.SSS").appending("Z").replacingOccurrences(of: " ", with: "T")
    var accX: String = "N/A"
    var accY: String = "N/A"
    var accZ: String = "N/A"
    var accLinX: String = "N/A"
    var accLinY: String = "N/A"
    var accLinZ: String = "N/A"
    var accUncX: String = "N/A"
    var accUncY: String = "N/A"
    var accUncZ: String = "N/A"
    var gyrX: String = "N/A"
    var gyrY: String = "N/A"
    var gyrZ: String = "N/A"
    var graX: String = "N/A"
    var graY: String = "N/A"
    var graZ: String = "N/A"
    var magX: String = "N/A"
    var magY: String = "N/A"
    var magZ: String = "N/A"
    var temp: String = "N/A"
    
    static var csvDesc: String {
        return "Time,Acc_X,Acc_Y,Acc_Z,AccLin_X,AccLin_Y,AccLin_Z,Gyr_X,Gyr_Y,Gyr_Z,Mag_X,Mag_Y,Mag_Z,Gra_X,Gra_Y,Gra_Z"
    }
    
    var csvValue: String {
        return "\(time),\(accX),\(accY),\(accZ),\(accLinX),\(accLinY),\(accLinZ),\(gyrX),\(gyrY),\(gyrZ),\(magX),\(magY),\(magZ),\(graX),\(graY),\(graZ)"
    }
    
    func convertToDict(keys: [String]?) -> NSDictionary? {
        var dict: NSDictionary?
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary
            if (keys != nil && dict != nil) {
                let newDict = NSMutableDictionary()
                for key in keys! {
                    if (dict![key] != nil) {
                        newDict[key] = dict![key]
                    }
                }
                dict = newDict
            }
        } catch {
            print(error)
        }
        return dict
    }
}
