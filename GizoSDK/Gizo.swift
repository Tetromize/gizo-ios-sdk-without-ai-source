//
//  Gizo.swift
//  GizoSDK
//
//  Created by Hepburn on 2023/12/4.
//

import UIKit

public class Gizo: NSObject {
    static public var app: GizoApp=GizoApp()
    
    static public var options: GizoAppOptions? {
        get {
            return GizoCommon.shared.options
        }
        set(newOptions) {
            GizoCommon.shared.options = newOptions
        }
    }
    
    static public func initialize(
        delegate: GizoDelegate, options: GizoAppOptions) {
//        GizoCommon.shared.delegate = delegate
        GizoCommon.shared.options = options
        TokenValidateManager.shared.checkLicense()
    }
    
    static public func hello() {
        print("hello")
    }
}
