//
//  GizoGpsSetting.swift
//  GizoSDK
//
//  Created by Hepburn on 2023/12/4.
//

import UIKit

public class GizoGpsSetting: GizoBaseSetting {
    public var allowGps: Bool=false
    public var mapBoxKey: String=""
    public var interval: Int=1000
    public var maxWaitTime: Int=1000
    public var withForegroundService: Bool=true
    public var saveCsvFile: Bool=false
    public var fileLocation: String=FileLocationPath.Cache
    public var saveDataTimerPeriod: Int=1000
}
