//
//  MotionManager.swift
//  Gizo
//
//  Created by Hepburn on 2023/10/18.
//

import Foundation
import UIKit
import CoreMotion

public protocol MotionManagerDelegate : NSObjectProtocol {
    func didUpdateMotion(orientation: UIDeviceOrientation, isValidInterface: Bool)
}

class MotionManager: NSObject {
    private var motionManager: CMMotionManager!
    public var shootingOrientation: UIDeviceOrientation = UIDeviceOrientation.portrait
    public var isValidInterfaceOrientation: Bool = false
//    public var isMotionUpdate: Bool = false
    public var delegate: MotionManagerDelegate!
    public var accX: Double?
    public var accY: Double?
    public var accZ: Double?
    public var accLinX: Double?
    public var accLinY: Double?
    public var accLinZ: Double?
    public var gyrX: Double?
    public var gyrY: Double?
    public var gyrZ: Double?
    public var graX: Double?
    public var graY: Double?
    public var graZ: Double?
    public var magX: Double?
    public var magY: Double?
    public var magZ: Double?
    public var updateInterval: Double = 0.01
    public var gizoAnalysisDelegate: GizoAnalysisDelegate?
    var accDict: NSDictionary?
    var gyrDict: NSDictionary?
    var magDict: NSDictionary?
    var graDict: NSDictionary?
    var accLinDict: NSDictionary?
    let model = TripCSVIMUModel.init()

    static let shared = MotionManager()
    
    override init() {
        super.init()
        motionManager = CMMotionManager.init()
        motionManager.deviceMotionUpdateInterval = updateInterval
    }

    public func startUpdateAccelerometer() {
        let imuSetting = GizoCommon.shared.options?.imuSetting
        let orientationSetting = GizoCommon.shared.options?.orientationSetting

        if (self.motionManager.isAccelerometerAvailable) {
            self.motionManager.accelerometerUpdateInterval = updateInterval
            self.motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (accelerometerData, error) in
                let x = (accelerometerData?.acceleration.x)!
                let y = (accelerometerData?.acceleration.y)!
                let z = (accelerometerData?.acceleration.z)!
                if (imuSetting?.allowAccelerationSensor != nil && (imuSetting?.allowAccelerationSensor)!) {
                    self.accX = x*9.81
                    self.accY = y*9.81
                    self.accZ = z*9.81
                    self.model.accX = String(self.accX ?? 0)
                    self.model.accY = String(self.accY ?? 0)
                    self.model.accZ = String(self.accZ ?? 0)
                    self.gizoAnalysisDelegate?.onAccelerationSensor(accX: self.accX, accY: self.accY, accZ: self.accZ)
                    self.accDict = self.model.convertToDict(keys: ["accX", "accY", "accZ"])
                    self.sendImuSensor()
                }
                if (orientationSetting?.allowGravitySensor != nil && (orientationSetting?.allowGravitySensor)!) {
                    if ((fabs(y) + 0.1) >= fabs(x)) {
                        if (y >= 0.1) {
                            self.shootingOrientation = UIDeviceOrientation.portraitUpsideDown
                        }
                        else {
                            self.shootingOrientation = UIDeviceOrientation.portrait
                        }
                    }
                    else {
                        if (x >= 0.1) {
                            self.shootingOrientation = UIDeviceOrientation.landscapeRight
                        }
                        else if (x <= 0.1) {
                            self.shootingOrientation = UIDeviceOrientation.landscapeLeft
                        }
                        else {
                            self.shootingOrientation = UIDeviceOrientation.portrait
                        }
                    }
                    
                    if (fabs(z) < 0.4) {
                        self.isValidInterfaceOrientation = true
                    }
                    else {
                        self.isValidInterfaceOrientation = false
                    }
                    
                    if (self.delegate != nil) {
                        self.delegate.didUpdateMotion(orientation: self.shootingOrientation, isValidInterface: self.isValidInterfaceOrientation)
                    }
                }
            }
        }
    }

    public func stopUpdateAccelerometer() {
        if (self.motionManager.isAccelerometerActive) {
            self.motionManager.stopAccelerometerUpdates()
        }
    }

    public func startUpdateGyro() {
        if (self.motionManager.isGyroAvailable) {
            self.motionManager.gyroUpdateInterval = updateInterval
            self.motionManager.startGyroUpdates(to: OperationQueue.current!) { (gyroData, error) in
//                if (gyroData != nil) {
//                    self.isMotionUpdate = true
//                }
                self.gyrX = (gyroData?.rotationRate.x)!
                self.gyrY = (gyroData?.rotationRate.y)!
                self.gyrZ = (gyroData?.rotationRate.z)!
                self.gizoAnalysisDelegate?.onGyroscopeSensor(gyrX: self.gyrX, gyrY: self.gyrY, gyrZ: self.gyrZ)

            }
        }
    }
    
    public func stopUpdateGyro() {
        if (self.motionManager.isGyroActive) {
            self.motionManager.stopGyroUpdates()
        }
    }
    
    public func startUpdateMagnetometer() {
        if (self.motionManager.isMagnetometerAvailable) {
            self.motionManager.magnetometerUpdateInterval = updateInterval
            self.motionManager.startMagnetometerUpdates(to: OperationQueue.current!) { (magData, error) in
//                if (magData != nil) {
//                    self.isMotionUpdate = true
//                }
                self.magX = (magData?.magneticField.x)!
                self.magY = (magData?.magneticField.y)!
                self.magZ = (magData?.magneticField.z)!
                self.model.magX = String(self.magX ?? 0)
                self.model.magY = String(self.magY ?? 0)
                self.model.magZ = String(self.magZ ?? 0)
                self.gizoAnalysisDelegate?.onMagneticSensor(magX: self.magX, magY: self.magY, magZ: self.magZ)
                self.magDict = self.model.convertToDict(keys: ["magX", "magY", "magZ"])
                self.sendImuSensor()
            }
        }
    }
    
    public func stopUpdateMagnetometer() {
        if (self.motionManager.isMagnetometerActive) {
            self.motionManager.stopMagnetometerUpdates()
        }
    }
    
    public func startUpdateDeviceMotion() {
        if (motionManager.isDeviceMotionAvailable) {
            motionManager.deviceMotionUpdateInterval = updateInterval
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: { (motion, error) in
//                if (motion != nil) {
//                    self.isMotionUpdate = true
//                }
                self.graX = (motion?.gravity.x)!
                self.graY = (motion?.gravity.y)!
                self.graZ = (motion?.gravity.z)!
                self.accLinX = (motion?.userAcceleration.x)!*9.81
                self.accLinY = (motion?.userAcceleration.y)!*9.81
                self.accLinZ = (motion?.userAcceleration.z)!*9.81
                self.model.graX = String(self.graX ?? 0)
                self.model.graY = String(self.graY ?? 0)
                self.model.graZ = String(self.graZ ?? 0)
                self.model.accLinX = String(self.accLinX ?? 0)
                self.model.accLinY = String(self.accLinY ?? 0)
                self.model.accLinZ = String(self.accLinZ ?? 0)

                self.gizoAnalysisDelegate?.onGravitySensor(graX: self.graX, graY: self.graY, graZ: self.graZ)
                self.gizoAnalysisDelegate?.onLinearAccelerationSensor(accLinX: self.accLinX, accLinY: self.accLinY, accLinZ: self.accLinZ)
                self.graDict = self.model.convertToDict(keys: ["graX", "graY", "graZ"])
                self.accLinDict = self.model.convertToDict(keys: ["accLinX", "accLinY", "accLinZ"])
                self.sendImuSensor()


//                //翻滚
//                let roll = motion!.attitude.roll
//                let rollDegrees = roll * 180 / Double.pi
//                //偏航
//                let yaw = motion!.attitude.yaw
//                let yawDegrees = yaw * 180 / Double.pi
//                //俯仰
//                let pitch = motion!.attitude.pitch
//                let pitchDegrees = pitch * 180 / Double.pi
//
//                print("Roll:%.2f", rollDegrees)
//                print("Yaw:%.2f", yawDegrees)
//                print("Pitch:%.2f", pitchDegrees)
            })
        }
    }
    
    func sendImuSensor(){
        self.gizoAnalysisDelegate?.onImuSensor(acceleration: accDict, linearAcceleration: accLinDict, gyroscope: gyrDict, magnetic: magDict, gravity: graDict)
    }
    
    public func stopUpdateDeviceMotion() {
        if (motionManager.isDeviceMotionAvailable) {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    public func startMotion() {
        let imuSetting = GizoCommon.shared.options?.imuSetting
        let orientationSetting = GizoCommon.shared.options?.orientationSetting
        self.updateInterval = Double(imuSetting?.saveDataTimerPeriod ?? 25)/1000
        if (imuSetting?.allowAccelerationSensor != nil && (imuSetting?.allowAccelerationSensor)! || orientationSetting?.allowGravitySensor != nil && (orientationSetting?.allowGravitySensor)!) {
            startUpdateAccelerometer()
        }
        if (imuSetting?.allowAccelerationSensor != nil && (imuSetting?.allowAccelerationSensor)!) {
            startUpdateDeviceMotion()
        }
        if (imuSetting?.allowGyroscopeSensor != nil && (imuSetting?.allowGyroscopeSensor)!) {
            startUpdateGyro()
        }
        if (imuSetting?.allowMagneticSensor != nil && (imuSetting?.allowMagneticSensor)!) {
            startUpdateMagnetometer()
        }
    }
    
    public func stopMotion() {
        stopUpdateAccelerometer()
        stopUpdateGyro()
        stopUpdateMagnetometer()
        stopUpdateDeviceMotion()
    }
}
