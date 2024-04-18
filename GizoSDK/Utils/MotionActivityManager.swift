//
//  MotionActivityManager.swift
//  Gizo
//
//  Created by Hepburn on 2023/10/24.
//

import UIKit
import CoreMotion

public protocol MotionActivityManagerDelegate : NSObjectProtocol {
    func didMotionActivityUpdate(type: MotionActivityType, typeName: String)
}

public enum MotionActivityType : Int {
    case unknown = 0
    case stationary = 1
    case walking = 2
    case running = 3
    case automotive = 4
    case cycling = 5
}

class MotionActivityManager: NSObject {
    public weak var delegate: MotionActivityManagerDelegate?
    private var activityManager: CMMotionActivityManager = CMMotionActivityManager.init()
    public var type: MotionActivityType = .unknown
    public var preType: MotionActivityType? = nil
    public var typeName: String = "Unknown"
    private var activityTimer: Timer?
    private var BufferSize: Int = 120
    private var BufferM: Int = 20
    private var C_thrsh: Float = 0.6
    private var activityBuffer: [MotionActivityType] = Array.init(repeating: .unknown, count: 120)
    private var confidence: String = "low"
    
//    private var index: Int = 0
//    private var activityList: [String] = []
    
    static let shared = MotionActivityManager()

    public func startUpdateMotionActivity() {
        if (!CMMotionActivityManager.isActivityAvailable()) {
            return
        }
        if (activityTimer == nil) {
            activityTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(onTimeCheck), userInfo: nil, repeats: true)
//            activityTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(onTimeCheck2), userInfo: nil, repeats: true)
//            readActivityList()
        }
        activityManager.startActivityUpdates(to: OperationQueue.current!) { motionActivity in
            if (motionActivity != nil) {
                if (motionActivity!.confidence == .low) {
                    self.confidence = "low"
                }
                else if (motionActivity!.confidence == .medium) {
                    self.confidence = "mid"
                }
                else if (motionActivity!.confidence == .high) {
                    self.confidence = "high"
                }
                self.type = .unknown
                self.typeName = "Unknown"
                if (motionActivity!.stationary) {
                    self.type = .stationary
                    self.typeName = "Stationary"
                }
                else if (motionActivity!.walking) {
                    self.type = .walking
                    self.typeName = "Walking"
                }
                else if (motionActivity!.running) {
                    self.type = .running
                    self.typeName = "Running"
                }
                else if (motionActivity!.automotive) {
                    self.type = .automotive
                    self.typeName = "Automotive"
                }
                else if (motionActivity!.cycling) {
                    self.type = .cycling
                    self.typeName = "Cycling"
                }
            }
        }
    }
    
    public func stopUpdateMotionActivity() {
        if (!CMMotionActivityManager.isActivityAvailable()) {
            return
        }
        activityManager.stopActivityUpdates()
        self.type = .unknown
    }
    
    @objc func onTimeCheck() {
        let model = LogActivityModel()
        model.activity = self.typeName
        model.confidence = self.confidence
//        LogActivityManager.shared.appendActivityCSV(model: model)
//        if (self.confidence == "low") {
//            return
//        }
        activityRecognize(activityType: self.type)
    }
    
    func activityRecognize(activityType: MotionActivityType) {
        activityBuffer.append(activityType)
        activityBuffer.remove(at: 0)
        
        let act_st = getMaxOccurActivity(suffix: true)
        let act_lt = getMaxOccurActivity(suffix: false)
        if (act_st == .unknown || act_st == .stationary) {
            if (act_st == act_lt) {
                
                updateActivity(type: act_st)
            }
            else {
                //keep the current act
            }
        }
        else {
            
            updateActivity(type: act_st)
        }
    }
    
    func updateActivity(type: MotionActivityType) {
        if (preType != type) {
            preType = type
            let name = getActivityTypeName2(type: type)
            let userInfo = ["start": name]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "kMsg_UpdateActivity"), object: nil, userInfo: userInfo)
        }
        let typeName = getActivityTypeName(type: type)
        if (self.delegate != nil) {
            self.delegate?.didMotionActivityUpdate(type: type, typeName: typeName)
        }
//        ActivityTransitionManager.shared.updateActivity(type: type)
    }
    
    func getMaxOccurActivity(suffix: Bool=false) -> MotionActivityType {
        var buffer = activityBuffer
        var length = BufferSize
        if (suffix) {
            buffer = activityBuffer.suffix(BufferM)
            length = BufferM
        }
        var numbers: [Int:Int] = [:]
        for t in buffer {
            if (numbers[t.rawValue] == nil) {
                numbers[t.rawValue] = 0
            }
            numbers[t.rawValue]! += 1
        }
        var maxNum: Int = 0
        var maxType: MotionActivityType = .unknown
        for t in numbers.keys {
            if (numbers[t]! > maxNum) {
                maxNum = numbers[t]!
                maxType = MotionActivityType.init(rawValue: t)!
            }
        }
        let confidence: Float = Float(maxNum)/Float(length)
//
        if (confidence >= C_thrsh) {
            return maxType
        }
        return .unknown
    }
    
    func getActivityType(name: String) -> MotionActivityType {
        var type: MotionActivityType = .unknown
        if (name == "Stationary") {
            type = .stationary
        }
        else if (name == "Walking") {
            type = .walking
        }
        else if (name == "Running") {
            type = .running
        }
        else if (name == "Automotive") {
            type = .automotive
        }
        else if (name == "Cycling") {
            type = .cycling
        }
        return type
    }
    
    func getActivityTypeName(type: MotionActivityType) -> String {
        var name: String = "Unknown"
        if (type == .stationary) {
            name = "Stationary"
        }
        else if (type == .walking) {
            name = "Walking"
        }
        else if (type == .running) {
            name = "Running"
        }
        else if (type == .automotive) {
            name = "Automotive"
        }
        else if (type == .cycling) {
            name = "Cycling"
        }
        return name
    }
    
    func getActivityTypeName2(type: MotionActivityType) -> String {
        var name: String = "Unknown"
        if (type == .stationary) {
            name = "STILL"
        }
        else if (type == .walking) {
            name = "WALKING"
        }
        else if (type == .running) {
            name = "RUNNING"
        }
        else if (type == .automotive) {
            name = "IN_VEHICLE"
        }
        else if (type == .cycling) {
            name = "CYCLING"
        }
        return name
    }
    
//    @objc func onTimeCheck2() {
//        index += 5
//        if (index >= activityList.count) {
//            return
//        }
//        let line = activityList[index]
//        let array = line.components(separatedBy: ",")
//        self.typeName = array[1]
//        self.confidence = array[2]
//        self.type = getActivityType(name: self.typeName)
//
//        onTimeCheck()
//    }
//
//    func readActivityList() {
//        do {
//            let path = Bundle.main.path(forResource: "Activity", ofType: "csv")
//            let text = try NSString.init(contentsOfFile: path!, encoding: String.Encoding.utf8.rawValue)
//            activityList.removeAll()
//            for line in text.components(separatedBy: .newlines) {
//                activityList.append(line)
//            }
//        }
//        catch {
//
//        }
//    }
}
