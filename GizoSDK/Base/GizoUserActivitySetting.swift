//
//  GizoUserActivitySetting.swift
//  GizoSDK
//
//  Created by Meysam Farmani on 2/7/24.
//

import UIKit

public class GizoUserActivitySetting: GizoBaseSetting {
    public var allowUserActivity: Bool=false
    public var saveCsvFile: Bool=false
    public var fileLocation: String=FileLocationPath.Cache
}

