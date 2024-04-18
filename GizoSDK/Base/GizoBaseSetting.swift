//
//  GizoBaseSetting.swift
//  GizoSDK
//
//  Created by Hepburn on 2023/12/4.
//

import UIKit

//public class AnalysisDelegateType {
//    public static var Auto: String {
//        return "AUTO"
//    }
//    
//    public static var CPU: String {
//        return "CPU"
//    }
//    
//    public static var GPU: String {
//        return "GPU"
//    }
//    
//    public static var NNAPI: String {
//        return "NNAPI"
//    }
//}

public class Quality {
    public static var SD: String {
        return "SD"
    }
    
    public static var HD: String {
        return "HD"
    }
    
    public static var FHD: String {
        return "FHD"
    }
    
    public static var UHD: String {
        return "UHD"
    }
    
    public static var Lowest: String {
        return "Lowest"
    }
    
    public static var Highest: String {
        return "Highest"
    }
}

public class FileLocationPath {
    public static var Cache: String {
//        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!+"/Cache/"
    }
}

public class GizoBaseSetting: NSObject {

}
