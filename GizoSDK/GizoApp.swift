//
//  GizoApp.swift
//  GizoSDK
//
//  Created by Hepburn on 2023/12/4.
//

import UIKit

public class GizoApp: NSObject {
    public var gizoAnalysis: GizoAnalysis=GizoAnalysis()
//    public func loadModel() {
//        GizoCommon.shared.delegate?.setLoadModelObserver(status: LoadModelStatus.LOADING)
//        let modelPath: String? = checkModelPath()
//        if (modelPath != nil) {
//            PythonManager.sharedInstance.loadModelInThread(modelPath: modelPath!)
//            return
//        }
//        GizoCommon.shared.delegate?.setLoadModelObserver(status: LoadModelStatus.FAILED)
//    }
//    
//    func checkModelPath() -> String? {
//        var modelName: String? = GizoCommon.shared.options?.analysisSetting.modelName
//        if (modelName != nil) {
//            if (modelName!.hasSuffix(".mlmodelc") || modelName!.hasSuffix(".mlmodel")) {
//                modelName = modelName!.replacingOccurrences(of: ".mlmodelc", with: "")
//                modelName = modelName!.replacingOccurrences(of: ".mlmodel", with: "")
//            }
//            let path: String? = Bundle.main.path(forResource: modelName, ofType: "mlmodelc")
//            if (FileManager.default.fileExists(atPath: path!)) {
//                return path!
//            }
//        }
//        return nil
//    }
}
