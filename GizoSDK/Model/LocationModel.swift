//
//  LocationModel.swift
//  Gizo
//
//  Created by Hepburn on 2023/9/21.
//

import Foundation

public struct LocationModel: Codable {
    var latitude: Double?
    var longitude: Double?
    var speed: String?
    var speedValue: Int?
    var course: Double?
    var altitude: Double?
}
