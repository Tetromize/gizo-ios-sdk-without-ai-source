//
//  BaseModel.swift
//  Gizo
//
//  Created by Hepburn on 2023/9/19.
//

import Foundation

struct BaseModel: Codable {
    
    public static func getStringValue(dict: NSDictionary, key: String) -> String {
        let obj = dict[key] as AnyObject
        if (obj.isKind(of: NSClassFromString("NSString")!)) {
            return obj as! String
        }
        let number: NSNumber = obj as! NSNumber
        return number.stringValue
    }
    
    public static func dict2JsonStr(dict: NSDictionary) -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            return String.init(data: data, encoding: String.Encoding.utf8)
        } catch {
            print("jsonDict2String error")
        }
        return nil
    }
    
    public static func JsonStr2Dict(text: String) -> NSDictionary? {
        do {
            let data = text.data(using: .utf8)
            return try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary
        } catch {
            print("jsonDict2String error")
        }
        return nil
    }
    
    public static func createDir(path: String) {
        do {
            if (!FileManager.default.fileExists(atPath: path)) {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            print("FileManager createDirectory error! path:\(path)")
        }
    }
    
    public static func saveTextFile(path: String, text: String) {
        do {
            try text.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("FileManager createDirectory error! path:\(path)")
        }
    }
    
    public static func saveDictFile(path: String, dict: NSDictionary) {
        let jsonStr = BaseModel.dict2JsonStr(dict: dict)
        saveTextFile(path: path, text: jsonStr!)
    }
    
    public static func appendToDictFile(path: String, params: [String: Any]) {
        do {
            let text = try String.init(contentsOfFile: path, encoding: .utf8)
            let dict = JsonStr2Dict(text: text)
            if (dict != nil) {
                let newDict = NSMutableDictionary.init(dictionary: dict!)
                for key in params.keys {
                    newDict.setObject(params[key], forKey: NSString(string: key))
                }
                saveDictFile(path: path, dict: newDict)
            }
        } catch {
            print("FileManager createDirectory error! path:\(path)")
        }
    }
    
    public static var cachePath: String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
    }
    
    public static var docPath: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    }
}
