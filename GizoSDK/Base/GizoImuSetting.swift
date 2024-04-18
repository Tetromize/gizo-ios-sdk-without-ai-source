//
//  GizoImuSetting.swift
//  GizoSDK
//
//  Created by Hepburn on 2023/12/4.
//

import UIKit

public class GizoImuSetting: GizoBaseSetting {
    public var allowAccelerationSensor: Bool=false
    public var allowMagneticSensor: Bool=false
    public var allowGyroscopeSensor: Bool=false
    public var saveCsvFile: Bool=false
    public var fileLocation: String=FileLocationPath.Cache
    public var saveDataTimerPeriod: Int=10
}
