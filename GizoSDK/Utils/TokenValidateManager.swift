//
//  TokenValidateManager.swift
//  GizoSDK
//
//  Created by Hepburn on 2023/12/30.
//

import UIKit

public class TokenValidateManager: NSObject {
    public static let shared = TokenValidateManager()
    public var isValidate: Bool = false
    
    public func checkLicense() {
        var publicKey = """
            MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmvckenzK7iS7fipVK5sj\
            0KJ2KN7O+xY5Ph7P7HFaJh+StJ9qISUv2vQNsySsAOvjPxt2q0bXJ4WcIqtjPfUr\
            0Dwt8lpFhDao4F9tLlwgJ+gG7Cg087I/ZHzLQPByuUyxGmvvHrYHIFK7GD92yiIa\
            TiyCsOex7KAC7KTkFZcVD2Lr1m4pRw97k7erdViPXPqAXGxQMWr3qKpnKgg9+C3u\
            99tm79FA29Mlp4YfyGrsWplnJV8bYsPzSfg07pp6MecULYXKPM+eCZ1B9NbT4e5m\
            WEHK2MSwLFwEtiloFZoIQF+evO86cPWxS0H2F+ev0LD7/z3d8h9nYGnp/3iUHLVa\
            wwIDAQAB
            """
//        let publicKey: String? = readPublicKey()
//        if (publicKey != nil) {
//            checkLicense(publicKey: publicKey!)
//        }
        
        checkLicense(publicKey: publicKey)
    }
    
    func getBundlePath(name: String) -> String? {
        let path: String? = NSString.init(string: Bundle.main.resourcePath!).appendingPathComponent(name)
        if (path != nil) {
            return path
        }
        var bundlePath = Bundle.main.path(forResource: "GizoSDK-iOS_GizoSDK-iOS", ofType: "bundle")
        if (bundlePath == nil) {
            print("[GizoSDK] Gizo.bundle not found")
            return nil
        }
        bundlePath = bundlePath!.appending("/Gizo.bundle")
        if (!FileManager.default.fileExists(atPath: bundlePath!)) {
            print("[GizoSDK] Gizo.bundle not found!")
            return nil
        }
        return NSURL.fileURL(withPath: bundlePath!).appendingPathComponent(name).path
    }
    
    func readPublicKey() -> String? {
        let path: String? = getBundlePath(name: "publickey.pem")
        if (path == nil) {
            print("[GizoSDK] readPublicKey error: publickey.pem not found!")
            return nil
        }
        if (FileManager.default.fileExists(atPath: path!)) {
            do {
                let data: Data? = try Data.init(contentsOf: URL.init(fileURLWithPath: path!))
                if (data != nil) {
                    var text: String? = String.init(data: data!, encoding: .utf8)
                    if (text != nil) {
                        text = text?.replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
                        text = text?.replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
                        text = text?.replacingOccurrences(of: "\r", with: "")
                        text = text?.replacingOccurrences(of: "\n", with: "")
                        return text
                    }
                }
            }
            catch {
                print("[GizoSDK] readPublicKey error:")
                print(error)
            }
        }
        else {
            print("[GizoSDK] readPublicKey error: publickey.pem not found")
        }
        return nil
    }
    
    func checkLicense(publicKey: String) {
        var path: String? = self.licensePath
        if (!FileManager.default.fileExists(atPath: path!)) {
            path = getBundlePath(name: "license.json")
            if (path == nil) {
                print("[GizoSDK] checkLicense error: license.json not found")
                return
            }
            if (!FileManager.default.fileExists(atPath: path!)) {
                print("[GizoSDK] checkLicense error: license.json not found!")
                return
            }
        }
        do {
            let data: Data? = try Data.init(contentsOf: URL.init(fileURLWithPath: path!))
            if (data != nil) {
                let text: String? = String.init(data: data!, encoding: .utf8)
                if (text != nil) {
                    let licenseObj: NSDictionary? = JsonStr2Dict(text: text!)
                    if (licenseObj != nil) {
                        let licenseText: String? = licenseObj!["license"] as! String?
                        if (licenseText != nil) {
                            print("[GizoSDK] licenseText:\(licenseText!)")
                            let base64decData: Data? = Data.init(base64Encoded: licenseText!)
                            if (base64decData != nil) {
                                let jsonText: String? = String.init(data: base64decData!, encoding: .utf8)
                                if (jsonText != nil) {
                                    print("[GizoSDK] jsonText:\(jsonText!)")
                                    let jsonObj: NSDictionary? = JsonStr2Dict(text: jsonText!)
                                    if (jsonObj != nil) {
                                        let sign1: String? = jsonObj!["signature"] as? String
                                        print("[GizoSDK] signature1:\(String(describing: sign1))")
                                        let dict: NSMutableDictionary = NSMutableDictionary.init(dictionary: jsonObj!)
                                        dict.removeObject(forKey: "signature")
                                        let verify = zz_rsaVerify(dict, sign1!, publicKey)
                                        print("[GizoSDK] verify:\(verify)")
                                        if (!verify) {
                                            return
                                        }
                                        self.isValidate = true
                                        var expireTime: String? = jsonObj!["expiration-date"] as? String
                                        if (expireTime != nil) {
                                            expireTime = expireTime!.replacingOccurrences(of: "T", with: " ")
                                            let time = DateTimeUtil.dateTimeFromString(expireTime!, format: "yyyy-MM-dd HH:mm:ss")
                                            let interval = time?.timeIntervalSinceNow
                                            if (interval != nil && interval! < 3600*24*7) {
                                                updateLicense(license: licenseText!)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else {
                        print("[GizoSDK] checkLicense error: licenseObj = nil")
                    }
                }
                else {
                    print("[GizoSDK] checkLicense error: text = nil")
                }
            }
            else {
                print("[GizoSDK] checkLicense error: data = nil")
            }
        }
        catch {
            print(error)
        }
    }
    
    var licensePath: String {
        let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        return NSString.init(string: docPath!).appendingPathComponent("license.json")
    }
    
    func updateLicense(license: String) {
        let params = ["license":license]
        HttpManager.shared.request(urlStr: "Auth/refresh-license", method: "POST", headers: nil, parameters: params) { [self] data in
            let jsonText: String? = dict2JsonStr(dict: data as! NSDictionary)
            if (jsonText != nil) {
                do {
                    let path = self.licensePath
                    if (FileManager.default.fileExists(atPath: path)) {
                        try FileManager.default.removeItem(atPath: path)
                    }
                    try jsonText!.write(toFile: path, atomically: true, encoding: .utf8)
                }
                catch {
                    print(error)
                }
            }
        } failure: { code, message in
        }
    }
    
    func dict2JsonStr(dict: NSDictionary) -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
            return String.init(data: data, encoding: String.Encoding.utf8)
        } catch {
            print("jsonDict2String error")
        }
        return nil
    }
    
    func JsonStr2Dict(text: String) -> NSDictionary? {
        do {
            let data = text.data(using: .utf8)
            return try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary
        } catch {
            print("jsonDict2String error")
        }
        return nil
    }
    
    func zz_rsaEncrypt(_ text: String, _ publicKey: String) -> String? {
        print("text:\(text)")
        print("publicKey:\(publicKey)")
        let ZZ_RSA_PUBLIC_KEY_TAG = "RSAUtil_PubKey"
        guard let textData = text.data(using: String.Encoding.utf8) else { return nil }
        let encryptedData = RSACrypt.encryptWithRSAPublicKey(textData, pubkeyBase64: publicKey, keychainTag: ZZ_RSA_PUBLIC_KEY_TAG)
        if ( encryptedData == nil ) {
            print("Error while encrypting")
            return nil
        } else {
            let encryptedDataText = encryptedData!.base64EncodedString(options: NSData.Base64EncodingOptions())
            return encryptedDataText
        }
    }
    
    func zz_rsaVerify(_ dict: NSMutableDictionary, _ sign: String, _ publicKey: String) -> Bool {
        let ZZ_RSA_PUBLIC_KEY_TAG = "RSAUtil_PubKey"
        let bundleId = Bundle.main.bundleIdentifier
        let text1 = "{\"id\":\"\(dict["id"]!)\",\"license-type\":\(dict["license-type"]!),\"expiration-date\":\"\(dict["expiration-date"]!)\",\"package-name\":\"\(bundleId!)\"}"
        return RSACrypt.verifySign(text1, sign, publicKey, ZZ_RSA_PUBLIC_KEY_TAG)
    }
}
