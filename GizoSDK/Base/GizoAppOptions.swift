//
//  GizoAppOptions.swift
//  GizoSDK
//
//  Created by Hepburn on 2023/12/4.
//

import UIKit

public class GizoAppOptions: NSObject {
    public var debug: Bool=true
    public var folderName: String="Gizo"
//    public var analysisSetting: GizoAnalysisSettings=GizoAnalysisSettings()
    public var imuSetting: GizoImuSetting=GizoImuSetting()
    public var gpsSetting: GizoGpsSetting=GizoGpsSetting()
//    public var videoSetting: GizoVideoSetting=GizoVideoSetting()
    public var batterySetting: GizoBatterySetting=GizoBatterySetting()
    public var orientationSetting: GizoOrientationSetting=GizoOrientationSetting()
    public var userActivitySetting: GizoUserActivitySetting=GizoUserActivitySetting()
}
