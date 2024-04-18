//
//  GizoCommon.swift
//  GizoSDK
//
//  Created by Hepburn on 2023/12/5.
//

import UIKit
import CoreLocation

//public enum LoadModelStatus: Int {
//    case LOADING = 0
//    case LOADED = 1
//    case FAILED = 2
//    case NOT_LOADED = 3
//}

public enum BatteryStatus: Int {
    case NORMAL = 0
    case LOW_BATTERY_WARNING = 1
    case LOW_BATTERY_STOP = 2
}

public enum VideoRecordStatus: Int {
    case Start = 0
    case Stop = 1
    case Pause = 2
    case Resume = 3
    case Status = 4
}

//public enum TTCStatus: Int {
//    case None = 0
//    case tailgating = 1
//    case collision = 2
//}

public protocol GizoDelegate : NSObjectProtocol {
//    func setLoadModelObserver(status: LoadModelStatus)
}

public protocol GizoAnalysisDelegate : NSObjectProtocol {
//    func onSessionStatus(inProgress: Bool, previewAttached: Bool)
//    func onAnalysisResult(preview: UIImage?, ttc: Float?, ttcStatus: TTCStatus, frontObjectDistance: Double?, egoSpeed: Int?, gpsTime: String)
//    func ttcCalculator(frontObjectDistance: Double?, egoSpeed: Int?, ttc: Float?)
//    func ttcStatusCalculator(ttc: Float?, egoSpeed: Int?, ttcStatus: TTCStatus)
    func onLocationChange(location: CLLocationCoordinate2D?, isGpsOn: Bool?)
    func onSpeedChange(speedLimitKph: Int?, speedKph: Int)
    func onRecordingEvent(status: VideoRecordStatus)
    func onBatteryStatusChange(status: BatteryStatus)
    func onGravityAlignmentChange(isAlign: Bool)
    func onLinearAccelerationSensor(accLinX: Double?, accLinY: Double?, accLinZ: Double?)
    func onAccelerationSensor(accX: Double?, accY: Double?, accZ: Double?)
//    func onAccelerationUncalibratedSensor(accUncX: Double?, accUncY: Double?, accUncZ: Double?)
    func onGyroscopeSensor(gyrX: Double?, gyrY: Double?, gyrZ: Double?)
    func onGravitySensor(graX: Double?, graY: Double?, graZ: Double?)
    func onMagneticSensor(magX: Double?, magY: Double?, magZ: Double?)
    func onImuSensor(acceleration: NSDictionary?, linearAcceleration: NSDictionary?, gyroscope: NSDictionary?, magnetic: NSDictionary?, gravity: NSDictionary?)
    func onUserActivity(type: String)
    func onThermalStatusChange(state: ProcessInfo.ThermalState)

}

class GizoCommon: NSObject {
//    var delegate: GizoDelegate?
    var options: GizoAppOptions?
    var isSavingSession: Bool=false
    static let shared = GizoCommon()

}
