//
//  DriveManager.swift
//  GizoSDK
//
//  Created by Hepburn on 2023/12/5.
//

import Foundation
import UIKit
import AVFoundation
import CoreLocation

class DriveManager : NSObject, VideoCaptureManagerDelegate, MBLocationManagerDelegate, MotionManagerDelegate, ThermalMonitorDelegate {
    
    private var orientationText: String!
    private var videoCaptureManager: VideoCaptureManager?
    private var lastWarnTime: Date?
    private var isCoverHidden: Bool=false
    private var videoIndex: Int=0
    public var cacheManager: TripCacheManager = TripCacheManager.init()
    private var gpsTimer: DispatchSourceTimer?
    private var imuTimer: DispatchSourceTimer?
    private var activityType: String = ""
    private var currentActivityType: String = ""
    public var batteryStatus: BatteryStatus=BatteryStatus.NORMAL
    private var collectUserActivity: Bool=false
    private var collectTTC: Bool=false
    public var inProgress: Bool=false
    public var previewAttached: Bool=false
    public var delegate: GizoAnalysisDelegate?
    var gizoOption = GizoCommon.shared.options
    var thermalState: ProcessInfo.ThermalState = .nominal
    public var thermalMonitor: ThermalMonitor?

    func thermalStateDidChange(to state: ProcessInfo.ThermalState) {
        print("Thermal state: \(state.rawValue)")

        self.thermalState = state
        if (state == .serious || state == .critical) {
//            self.stopRecording()
        }
    }
    
    func getVideoPath(videoPath: String) -> String {
        return cacheManager.checkCSVPath(csvPath: videoPath, name: "video", ext: ".mp4", createBlock: nil)
    }
    
    func lockPreview() {
        videoCaptureManager?.lockPreview()
    }
    
    func unlockPreview(previewView: UIView) {
        videoCaptureManager?.unlockPreview(previewView)
    }
    
    func attachPreview(previewView: UIView?) {
        videoCaptureManager?.attachPreview(previewView)
        if (previewView != nil) {
            previewAttached = true
        }
        else {
            previewAttached = false
        }
        self.delegate?.onSessionStatus(inProgress: inProgress, previewAttached: previewAttached)
    }
    
    func didUpdateMotion(orientation: UIDeviceOrientation, isValidInterface: Bool) {

//        print("didUpdateMotion:\(orientation)")
        if ((orientation == UIDeviceOrientation.landscapeLeft || orientation == UIDeviceOrientation.landscapeRight) && isValidInterface) {
            if (isCoverHidden) {
                return
            }
            isCoverHidden = true
        }
        else {
            if (!isCoverHidden) {
                return
            }
            isCoverHidden = false
        }
        self.delegate?.onGravityAlignmentChange(isAlign: isCoverHidden)
    }
    
    //MBLocationManagerDelegate
    func didUpdateLocation(model: LocationModel) {
        updateSpeedColor()
        var speedLimit: Int? = Int(LocationManager.shared.speedLimit)
        if (speedLimit == 0) {
            speedLimit = nil
        }
        self.delegate?.onLocationChange(location: CLLocationCoordinate2DMake(model.latitude ?? 0, model.longitude ?? 0), isGpsOn: true)
        self.delegate?.onSpeedChange(speedLimitKph: speedLimit, speedKph: model.speedValue ?? 0)
        if (!inProgress) {
            inProgress = true
            self.delegate?.onSessionStatus(inProgress: inProgress, previewAttached: previewAttached)
        }
    }
    
    func didUpdateSpeedLimit(speedLimit: Double?) {
        updateSpeedColor()
    }
    
    func updateSpeedColor() {
//        controlView.updateSpeedColor(speedOver: LocationManager.shared.isSpeedOver)
    }
    
    //VideoCaptureManagerDelegate
    func videoCaptureSampleBuffer(_ image: UIImage) {
//        if (PythonManager.sharedInstance.isModelLoaded) {
//            DispatchQueue.main.async {
//                let analysisSetting = self.gizoOption?.analysisSetting
//                if (analysisSetting?.allowAnalysis != nil &&
//                    (analysisSetting?.allowAnalysis)! &&
//                    self.batteryStatus == BatteryStatus.NORMAL) {
//                    self.videoCaptureManager?.isPythonUsing = true
//
//                    let startTime = NSDate.now.timeIntervalSince1970
//                    let img = PythonManager.sharedInstance.infer(img: image)
//                    let ret = PythonManager.sharedInstance.predict(image: img)
//
//                    self.appendTTCSCV(depth: ret, image: image)
//                    self.videoCaptureManager?.isPythonUsing = false
//
//                    if (ret != nil) {
//                        print("videoCaptureSampleBuffer ret:\(ret!)")
//                    }
//                    let endTime = NSDate.now.timeIntervalSince1970
//                    print("python time:\(endTime-startTime)")
//                }
//            }
//        }
    }
    
//    func videoCameraIntrinsicMatrix(_ text: String) {
//        let analysisSetting = gizoOption?.analysisSetting
//        if (analysisSetting?.allowAnalysis != nil && (analysisSetting?.allowAnalysis)! && analysisSetting?.saveMatrixFile != nil && (analysisSetting?.saveMatrixFile)!) {
//            cacheManager.appendMatrixTxt(text: text, txtPath: analysisSetting?.matrixFileLocation)
//        }
//    }
    
    func onRecordingEvent(_ status: Int32) {
        self.delegate?.onRecordingEvent(status: VideoRecordStatus(rawValue: Int(status))!)
    }
    
//    func getTTC(depth: Double?, speed: Double) -> Double {
//        if (speed < 13.89) {
//            return (depth ?? 0-2.0)/speed-0.1
//        }
//        else {
//            return (depth ?? 0-2.0)/speed
//        }
//    }
//
//    func onAnalysisResult(depth: Double?, speed: Int?, ttc: Float?, ttcStatus: TTCStatus, image: UIImage?) {
//        let time = DateTimeUtil.stringFromDateTime(NSDate.now)
//        if (self.delegate != nil) {
//            self.delegate?.onAnalysisResult(preview: image, ttc: ttc, ttcStatus: ttcStatus, frontObjectDistance: depth, egoSpeed: speed, gpsTime: time)
//            self.delegate?.ttcStatusCalculator(ttc: ttc, egoSpeed: speed, ttcStatus: ttcStatus)
//            self.delegate?.ttcCalculator(frontObjectDistance: depth, egoSpeed: speed, ttc: ttc)
//        }
//    }
//
//    func checkTTCWarning(depth: Double?, speed: Double, image: UIImage?) -> Double {
//        let analysisSetting = gizoOption?.analysisSetting
//        let collisionThreshold: Double = Double(analysisSetting?.collisionThreshold ?? 0.5)
//        let tailgatingThreshold: Double = Double(analysisSetting?.tailgatingThreshold ?? 1.0)
//        let ttc = getTTC(depth: depth, speed: speed)
//        var isCheck = false
//        if (speed > 11.1) {
//            if (ttc >= collisionThreshold && ttc < tailgatingThreshold) {
////                controlView.updateCollision()
//                onAnalysisResult(depth: depth, speed: Int(speed * 3.6), ttc: Float(ttc), ttcStatus: .tailgating, image: image)
//                isCheck = true
//            }
//            else if (ttc < collisionThreshold) {
//                let curTime = NSDate.now
//                var interval = 0.0
//                if (lastWarnTime != nil) {
//                    interval = curTime.timeIntervalSince(lastWarnTime!)
//                }
//                if (lastWarnTime == nil || interval > 15) {
////                    controlView.cleanCollision()
////                    _ = DriveWarnView.showWarnPop()
//                    lastWarnTime = curTime
//                }
//                onAnalysisResult(depth: depth, speed: Int(speed * 3.6), ttc: Float(ttc), ttcStatus: .collision, image: image)
//                isCheck = true
//            }
//        }
//        if (!isCheck) {
//            onAnalysisResult(depth: depth, speed: Int(speed * 3.6), ttc: Float(ttc), ttcStatus: .None, image: image)
//        }
//        return ttc
//    }
//
//    func appendTTCSCV(depth: Double?, image: UIImage?) {
//        let model = TripCSVTTCModel.init()
//        let speed: Int? = LocationManager.shared.locationModel?.speedValue
//        var speedValue: Double = 0.0
//        if (speed != nil) {
//            speedValue = Double(speed!) / 3.6
//            model.speed = String(speed ?? 0)
//        }
//        if (depth != nil) {
//            model.Depth = String(depth!)
//        }
//        if (speedValue > 11.1) {
//            let ttc = checkTTCWarning(depth: depth, speed: speedValue, image: image)
//            model.ttc = String(ttc)
//        }
//        else {
//            onAnalysisResult(depth: depth, speed: speed, ttc: nil, ttcStatus: .None, image: image!)
//        }
//        let analysisSetting = gizoOption?.analysisSetting
//        if (analysisSetting?.saveTtcCsvFile != nil && (analysisSetting?.saveTtcCsvFile)!) {
//            if(self.collectTTC){
//                cacheManager.appendTTCCSV(model: model, csvPath: analysisSetting?.ttcFileLocation)
//            }
//        }
//    }
    
    func stopVideoRecordAndTTC() {
//        controlView.changeRecordState(value: false)
//        videoCaptureManager?.isLowBattery = true
//        videoCaptureManager?.stopVideoRecorder()
    }
    
    func clearBatteryWarn() {
//        videoCaptureManager?.isLowBattery = false
    }
    
    @objc func onUploadActivity(noti: Notification) {
        let userInfo = noti.userInfo!
        currentActivityType = userInfo["start"] as! String
        
        self.delegate?.onUserActivity(type: currentActivityType)
        if(collectUserActivity){
            writeToUserActivityCSV(type: currentActivityType)
        }
    }

    @objc fileprivate func batteryDidChange() {
        let batterySetting = gizoOption?.batterySetting
        let batteryState = UIDevice.current.batteryState
        print("batteryDidChange batteryState=", batteryState.rawValue)
        if (batteryState == .unplugged || batteryState == .charging) {
            let batteryLevel = UIDevice.current.batteryLevel
            print("batteryDidChange batteryLevel=", batteryLevel)
            if (batteryLevel < Float(Float(batterySetting?.lowBatteryStop ?? 15)/100.0)) {
                self.delegate?.onBatteryStatusChange(status: BatteryStatus.LOW_BATTERY_STOP)
                self.batteryStatus = BatteryStatus.LOW_BATTERY_STOP
//                self.stopRecording()
            }
            else if (batteryLevel < Float(Float(batterySetting?.lowBatteryLimit ?? 25)/100)){
                self.delegate?.onBatteryStatusChange(status: BatteryStatus.LOW_BATTERY_WARNING)
                self.batteryStatus = BatteryStatus.LOW_BATTERY_WARNING
            }
            else {
                self.delegate?.onBatteryStatusChange(status: BatteryStatus.NORMAL)
                self.batteryStatus = BatteryStatus.NORMAL
            }
        }
    }
    
    func showLowBatteryView() {
//        stopVideoRecordAndTTC()
    }
    
    func initialVideoCapture(){
        
//        let analysisSetting = self.gizoOption?.analysisSetting
        let videoSetting = self.gizoOption?.videoSetting
        if(
//            (analysisSetting?.allowAnalysis != nil && analysisSetting?.allowAnalysis ?? false) ||
           (videoSetting?.allowRecording != nil && videoSetting?.allowRecording ?? false)){
            UIApplication.shared.isIdleTimerDisabled = true
            videoCaptureManager = VideoCaptureManager()
            
            videoCaptureManager?.delegate = self;
            videoCaptureManager?.startVideoCapture()
        }
        
        let userActivitySetting = gizoOption?.userActivitySetting
        if (userActivitySetting?.allowUserActivity != nil && (userActivitySetting?.allowUserActivity)!) {
            MotionActivityManager.shared.startUpdateMotionActivity()

            NotificationCenter.default.addObserver(self, selector: #selector(onUploadActivity), name: NSNotification.Name(rawValue: "kMsg_UpdateActivity"), object: nil)
        }
        
         let gpsSetting = gizoOption?.gpsSetting
         if (gpsSetting?.allowGps != nil && (gpsSetting?.allowGps)!) {
             LocationManager.shared.delegate = self
             LocationManager.shared.startLocationWithAuth(inUse: true)
         }
        
        let imuSetting = gizoOption?.imuSetting
        if ((imuSetting?.allowAccelerationSensor != nil && (imuSetting?.allowAccelerationSensor)!) ||
            (imuSetting?.allowGyroscopeSensor != nil && (imuSetting?.allowGyroscopeSensor)!) ||
            (imuSetting?.allowMagneticSensor != nil && (imuSetting?.allowMagneticSensor)!)) {
            
            MotionManager.shared.delegate = self
            MotionManager.shared.gizoAnalysisDelegate = self.delegate
            MotionManager.shared.startMotion()
        }
        
        let batterySetting = gizoOption?.batterySetting
        if (batterySetting?.checkBattery != nil && (batterySetting?.checkBattery)!) {
            UIDevice.current.isBatteryMonitoringEnabled = true
            NotificationCenter.default.addObserver(self, selector: #selector(batteryDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(batteryDidChange), name: UIDevice.batteryStateDidChangeNotification, object: nil)
            batteryDidChange()
        }
        if (batterySetting?.checkThermal != nil && (batterySetting?.checkThermal)!) {
            self.thermalMonitor = ThermalMonitor()
            self.thermalMonitor?.delegate = self
            self.thermalMonitor?.gizoAnalysisDelegate = self.delegate
            self.thermalMonitor?.currentThermal()
        }
        
        if (!inProgress) {
            inProgress = true
            self.delegate?.onSessionStatus(inProgress: inProgress, previewAttached: previewAttached)
        }
    }
    
    func startRecording() {
        cacheManager.tripTime = DateTimeUtil.stringFromDateTime(date: Date(), format: "yyyy-MM-dd-HH-mm-ss-SSS")

//        let analysisSetting = self.gizoOption?.analysisSetting
//        if(analysisSetting?.allowAnalysis != nil && analysisSetting?.allowAnalysis ?? false){
//            cacheManager.checkCSVPath(csvPath: analysisSetting?.ttcFileLocation ?? "", name: "ttc", ext: ".csv") { path in
//                self.cacheManager.createTTCCSV(csvPath: path)
//            }
//            collectTTC = true
//        }
        
        let videoSetting = gizoOption?.videoSetting
        if (videoSetting?.allowRecording != nil && (videoSetting?.allowRecording)!) {
            if (videoCaptureManager != nil && !(videoCaptureManager!.isShooting)) {
                videoIndex += 1
                let videoPath = getVideoPath(videoPath: (videoSetting?.fileLocation)!)
                videoCaptureManager?.startVideoRecorder(videoPath)
            }
        }
        
        let gpsSetting = gizoOption?.gpsSetting
        if (gpsSetting?.allowGps != nil && (gpsSetting?.allowGps)!) {
            writeToGpsCsv()
        }
        
        let imuSetting = gizoOption?.imuSetting
        if ((imuSetting?.allowAccelerationSensor != nil && (imuSetting?.allowAccelerationSensor)!) ||
            (imuSetting?.allowGyroscopeSensor != nil && (imuSetting?.allowGyroscopeSensor)!) ||
            (imuSetting?.allowMagneticSensor != nil && (imuSetting?.allowMagneticSensor)!)) {
            
            writeToImuCsv()
        }
        
        let userActivitySetting = gizoOption?.userActivitySetting
        if (userActivitySetting?.saveCsvFile != nil && (userActivitySetting?.saveCsvFile)!) {
            writeToUserActivityCSV(type: currentActivityType)
            collectUserActivity = true
        }
        
        let newAppCsvPath: String = cacheManager.checkCSVPath(csvPath: FileLocationPath.Cache, name: "app", ext: ".csv") { path in
            self.cacheManager.createAppCSV(csvPath: path)
        }
        
        let newPhoneEventsCsvPath: String = cacheManager.checkCSVPath(csvPath: FileLocationPath.Cache, name: "phone_events", ext: ".csv") { path in
            self.cacheManager.createPhoneEventCSV(csvPath: path)
        }
    }
    
    func stopRecording() {
        videoCaptureManager?.stopVideoRecorder()

        if (gpsTimer != nil) {
            gpsTimer?.cancel()
            gpsTimer = nil
        }
        
        if (imuTimer != nil) {
            imuTimer?.cancel()
            imuTimer = nil
        }
        
        activityType = ""
        collectUserActivity = false
        collectTTC = false
    }
    
    func stopVideoCapture(){
        videoCaptureManager?.delegate = nil
        videoCaptureManager?.stopVideoCapture()
        
        LocationManager.shared.delegate = nil
        LocationManager.shared.stopLocation()
        MotionManager.shared.delegate = nil
        MotionManager.shared.stopMotion()
        self.thermalMonitor?.delegate = nil
        self.thermalMonitor = nil
        
        NotificationCenter.default.removeObserver(self, name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIDevice.batteryStateDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.isBatteryMonitoringEnabled = false
                
        if (inProgress) {
            inProgress = false
            self.delegate?.onSessionStatus(inProgress: inProgress, previewAttached: previewAttached)
        }
    }
    
    func writeToGpsCsv(){
        let gpsSetting = gizoOption?.gpsSetting
        if (gpsSetting?.allowGps != nil && (gpsSetting?.allowGps)!) {
            let interval: Double = Double(gpsSetting?.saveDataTimerPeriod ?? 1000)/1000
            if (gpsTimer == nil) {
                gpsTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
                gpsTimer?.schedule(deadline: .now(), repeating: interval)
                gpsTimer?.setEventHandler {
                    self.onGPSTimeCheck()
                }
                gpsTimer?.activate()
            }
            LocationManager.shared.delegate = self
            LocationManager.shared.startLocationWithAuth(inUse: true)
        }
    }
    
    func writeToImuCsv(){
        let imuSetting = gizoOption?.imuSetting
        if ((imuSetting?.allowAccelerationSensor != nil && (imuSetting?.allowAccelerationSensor)!) ||
            (imuSetting?.allowGyroscopeSensor != nil && (imuSetting?.allowGyroscopeSensor)!) ||
            (imuSetting?.allowMagneticSensor != nil && (imuSetting?.allowMagneticSensor)!)) {
            let interval: Double = Double(imuSetting?.saveDataTimerPeriod ?? 10)/1000
            if (imuTimer == nil) {
                imuTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
                imuTimer?.schedule(deadline: .now(), repeating: interval)
                imuTimer?.setEventHandler {
                    self.onIMUTimeCheck()
                }
                imuTimer?.activate()
            }
            
            MotionManager.shared.delegate = self
            MotionManager.shared.startMotion()
        }
    }
    
    func writeToUserActivityCSV(type: String){
        if (type != activityType) {
            let model = TripCSVActivityModel.init()
            model.started = type
            model.stopped = activityType
            cacheManager.appendActivityCSV(model: model, csvPath: gizoOption?.userActivitySetting.fileLocation)
            activityType = type
        }
    }
    
    //GPS
    @objc func onGPSTimeCheck() {
        if (LocationManager.shared.isLocation) {
            let location: LocationModel = LocationManager.shared.locationModel!
            var model = TripCSVGPSModel.init()
            model.altitude = location.altitude
            model.latitude = location.latitude
            model.longitude = location.longitude
            model.speed = (location.speed)!
            model.course = location.course
            if (LocationManager.shared.speedLimit > 0) {
                model.speedLimit = String(LocationManager.shared.speedLimit)
            }
            
            let gpsSetting = gizoOption?.gpsSetting
            cacheManager.appendGPSCSV(model: model, csvPath: gpsSetting?.fileLocation)
        }
    }
    
    //IMU
    @objc func onIMUTimeCheck() {
        let imuSetting = gizoOption?.imuSetting
        if (imuSetting?.saveCsvFile != nil && (imuSetting?.saveCsvFile)!) {
            let model = TripCSVIMUModel.init()

            model.accX = MotionManager.shared.accX.map { String($0) } ?? "N/A"
            model.accY = MotionManager.shared.accY.map { String($0) } ?? "N/A"
            model.accZ = MotionManager.shared.accZ.map { String($0) } ?? "N/A"

            model.gyrX = MotionManager.shared.gyrX.map { String($0) } ?? "N/A"
            model.gyrY = MotionManager.shared.gyrY.map { String($0) } ?? "N/A"
            model.gyrZ = MotionManager.shared.gyrZ.map { String($0) } ?? "N/A"

            model.magX = MotionManager.shared.magX.map { String($0) } ?? "N/A"
            model.magY = MotionManager.shared.magY.map { String($0) } ?? "N/A"
            model.magZ = MotionManager.shared.magZ.map { String($0) } ?? "N/A"

            model.graX = MotionManager.shared.graX.map { String($0) } ?? "N/A"
            model.graY = MotionManager.shared.graY.map { String($0) } ?? "N/A"
            model.graZ = MotionManager.shared.graZ.map { String($0) } ?? "N/A"

            model.accLinX = MotionManager.shared.accLinX.map { String($0) } ?? "N/A"
            model.accLinY = MotionManager.shared.accLinY.map { String($0) } ?? "N/A"
            model.accLinZ = MotionManager.shared.accLinZ.map { String($0) } ?? "N/A"

            cacheManager.appendIMUCSV(model: model, csvPath: imuSetting?.fileLocation)
        }
    }
}
