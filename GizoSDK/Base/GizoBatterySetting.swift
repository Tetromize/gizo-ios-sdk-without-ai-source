//
//  GizoBatterySetting.swift
//  GizoSDK
//
//  Created by Hepburn on 2023/12/4.
//

import UIKit

public class GizoBatterySetting: GizoBaseSetting {
    public var checkBattery: Bool=false
    public var checkThermal: Bool=false
    public var lowBatteryLimit: Int=25
    public var lowBatteryStop: Int=15
    public var interval: Int=5000
}
