//
//  GizoAnalysis.swift
//  GizoSDK
//
//  Created by Hepburn on 2023/12/4.
//

import UIKit

public typealias doneCallback = () -> ()

public class GizoAnalysis: NSObject {
    var driveManager: DriveManager=DriveManager()
    
    public func start(lifecycleOwner: GizoAnalysisDelegate, onDone: doneCallback?) {
        if (!TokenValidateManager.shared.isValidate) {
            print("Token Invalidate")
            return
        }
        driveManager.delegate = lifecycleOwner
        driveManager.initialVideoCapture()
        if (onDone != nil) {
            onDone!()
        }
    }
    
    public func stop() {
        driveManager.stopVideoCapture()
        driveManager.delegate = nil
    }
    
    public func startSavingSession() {
        GizoCommon.shared.isSavingSession = true
        driveManager.startRecording()
    }
    
    public func stopSavingSession() {
        GizoCommon.shared.isSavingSession = false
        driveManager.stopRecording()
    }
    
    public func attachPreview(preview: UIView?) {
        driveManager.attachPreview(previewView: preview)
    }
    
    public func lockPreview() {
        driveManager.lockPreview()
    }
    
    public func unlockPreview(preview: UIView) {
        driveManager.unlockPreview(previewView: preview)
    }
}
