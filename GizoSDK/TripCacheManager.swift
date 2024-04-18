//
//  TripCacheManager.swift
//  Gizo
//
//  Created by Hepburn on 2023/9/22.
//

import Foundation

class TripCacheManager: NSObject {
    public var tripTime: String?
    public typealias CreateBlock = (_ path : String) -> ()
    
    func isDirectory(path: String) -> Bool {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    private func appendCSVLine(text: String, csvPath: String) {
        let outFile: FileHandle? = FileHandle.init(forWritingAtPath: csvPath)
        if (outFile == nil) {
            print("Open of file for writing failed")
        }
        let content = "\n"+text
        outFile?.seekToEndOfFile()
        let buffer = content.data(using: String.Encoding.utf8)
        if buffer != nil {
            outFile?.write(buffer!)
        }
        outFile?.closeFile()
    }
    
    public func checkCSVPath(csvPath: String, name: String, ext: String=".csv", createBlock: CreateBlock?) -> String {
        var newCsvPath: String = csvPath
        var isDirectory: ObjCBool = false
        var exists = FileManager.default.fileExists(atPath: newCsvPath, isDirectory: &isDirectory)
        if (exists) {
            if (isDirectory.boolValue) {
                newCsvPath = newCsvPath + tripTime!
                BaseModel.createDir(path: newCsvPath)
                newCsvPath = newCsvPath + "/" + name + ext
                createBlock?(newCsvPath)
            }
        }
        else {
            let isFound: Bool? = (newCsvPath.lowercased().hasSuffix(ext))
            if (isFound != nil && isFound! == false) {
                BaseModel.createDir(path: newCsvPath)
                newCsvPath = newCsvPath + "/" + tripTime!
                BaseModel.createDir(path: newCsvPath)
                newCsvPath = newCsvPath + "/" + name + ext
            }
            createBlock?(newCsvPath)
        }
        return newCsvPath
    }
    
    //Create GPS.csv
    func createGPSCSV(csvPath: String) {
        do {
            if (FileManager.default.fileExists(atPath: csvPath)) {
                return
            }
            try TripCSVGPSModel.csvDesc.write(toFile: csvPath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("FileManager createGPSCSV error! path:\(csvPath)")
        }
    }
    
    public func appendGPSCSV(model: TripCSVGPSModel, csvPath: String?) {
        if (csvPath == nil) {
            return
        }
        if (!GizoCommon.shared.isSavingSession) {
            return
        }
        let newCsvPath: String = checkCSVPath(csvPath: csvPath!, name: "gps", ext: ".csv") { path in
            self.createGPSCSV(csvPath: path)
        }
        appendCSVLine(text: model.csvValue, csvPath: newCsvPath)
    }
    
    //Create IMU.csv
    func createIMUCSV(csvPath: String) {
        do {
            if (FileManager.default.fileExists(atPath: csvPath)) {
                return
            }
            try TripCSVIMUModel.csvDesc.write(toFile: csvPath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("FileManager createIMUCSV error! path:\(csvPath)")
        }
    }
    
    public func appendIMUCSV(model: TripCSVIMUModel, csvPath: String?) {
        if (csvPath == nil) {
            return
        }
        if (!GizoCommon.shared.isSavingSession) {
            return
        }
        let newCsvPath: String = checkCSVPath(csvPath: csvPath!, name: "imu", ext: ".csv") { path in
            self.createIMUCSV(csvPath: path)
        }
        appendCSVLine(text: model.csvValue, csvPath: newCsvPath)
    }
    
//    //Create TTC.csv
//    func createTTCCSV(csvPath: String) {
//        do {
//            if (FileManager.default.fileExists(atPath: csvPath)) {
//                return
//            }
//            try TripCSVTTCModel.csvDesc.write(toFile: csvPath, atomically: true, encoding: String.Encoding.utf8)
//        } catch {
//            print("FileManager createTTCCSV error! path:\(csvPath)")
//        }
//    }
//    
//    public func appendTTCCSV(model: TripCSVTTCModel, csvPath: String?) {
//        if (csvPath == nil) {
//            return
//        }
//        if (!GizoCommon.shared.isSavingSession) {
//            return
//        }
//        let newCsvPath: String = checkCSVPath(csvPath: csvPath!, name: "ttc", ext: ".csv") { path in
//            self.createTTCCSV(csvPath: path)
//        }
//        appendCSVLine(text: model.csvValue, csvPath: newCsvPath)
//    }
    
    //Create Activity.csv
    func createActivityCSV(csvPath: String) {
        do {
            if (FileManager.default.fileExists(atPath: csvPath)) {
                return
            }
            try TripCSVActivityModel.csvDesc.write(toFile: csvPath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("FileManager createActivityCSV error! path:\(csvPath)")
        }
    }
    
    public func appendActivityCSV(model: TripCSVActivityModel, csvPath: String?) {
        if (csvPath == nil) {
            return
        }
        if (!GizoCommon.shared.isSavingSession) {
            return
        }
        let newCsvPath: String = checkCSVPath(csvPath: csvPath!, name: "act", ext: ".csv") { path in
            self.createActivityCSV(csvPath: path)
        }
        appendCSVLine(text: model.csvValue, csvPath: newCsvPath)
    }
    
    //Create Matrix.txt
    public func appendMatrixTxt(text: String, txtPath: String?) {
        if (txtPath == nil) {
            return
        }
        if (!GizoCommon.shared.isSavingSession) {
            return
        }
        let newTxtPath: String = checkCSVPath(csvPath: txtPath!, name: "matrix", ext: ".txt", createBlock: nil)
        BaseModel.saveTextFile(path: newTxtPath, text: text)
    }
    
    //App
    func createAppCSV(csvPath: String) {

        do {
            if (FileManager.default.fileExists(atPath: csvPath)) {
                return
            }
            try TripCSVAppModel.csvDesc.write(toFile: csvPath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("FileManager createAppCSV error! path:\(csvPath)")
        }
    }
    
    public func appendAppCSV(model: TripCSVAppModel, csvPath: String?)  {
        if (csvPath == nil) {
            return
        }
        if (!GizoCommon.shared.isSavingSession) {
            return
        }
        let newCsvPath: String = checkCSVPath(csvPath: csvPath!, name: "app", ext: ".csv") { path in
            self.createAppCSV(csvPath: path)
        }
        appendCSVLine(text: model.csvValue, csvPath: newCsvPath)
    }
    
    //PhoneEvent
    func createPhoneEventCSV(csvPath: String) {
        do {
            if (FileManager.default.fileExists(atPath: csvPath)) {
                return
            }
            try TripCSVPhoneModel.csvDesc.write(toFile: csvPath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("FileManager createAppCSV error! path:\(csvPath)")
        }
    }
    
    public func appendPhoneEventCSV(model: TripCSVPhoneModel, csvPath: String?) {
        if (csvPath == nil) {
            return
        }
        if (!GizoCommon.shared.isSavingSession) {
            return
        }
        let newCsvPath: String = checkCSVPath(csvPath: csvPath!, name: "phone_events", ext: ".csv") { path in
            self.createAppCSV(csvPath: path)
        }
        appendCSVLine(text: model.csvValue, csvPath: newCsvPath)
    }
}
