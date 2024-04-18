//
//  HttpManager.swift
//  Gizo
//
//  Created by Hepburn on 2023/9/6.
//

import Foundation
import UIKit

class HttpManager: NSObject, URLSessionDataDelegate {
    var defaultSession: URLSession?
    var operationQueue: OperationQueue?
    static var kBoundary: String = "----------------------------392786698179820914493732"
    public typealias successBlock = (_ data : Any?) -> ()
    public typealias failureBlock = (_ code : Int, _ message : String?) -> ()
    public static let shared = HttpManager()
    public static let serverUrl: String = "https://api.artificient.de"
    private let baseUrl = HttpManager.serverUrl+"/api/v1/"
    
    var defaultURLSession: URLSession {
        if (defaultSession == nil) {
            let sessionConfig: URLSessionConfiguration = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 300
            sessionConfig.timeoutIntervalForResource = 300
            sessionConfig.httpMaximumConnectionsPerHost = 1
            self.operationQueue = OperationQueue.init()
            self.operationQueue?.maxConcurrentOperationCount = 1
            defaultSession = URLSession.init(configuration: sessionConfig, delegate: self, delegateQueue: self.operationQueue)
        }
        return defaultSession!
    }
    
    func getFullUrlString(urlStr: String, parameters: [String: Any]?) -> String {
        let urlstr = self.baseUrl + urlStr
        let newStr = NSMutableString.init(string: urlstr)
        if (parameters != nil && parameters!.keys.count > 0) {
            var isFirst = true
            for key in parameters!.keys {
                if (isFirst) {
                    newStr.append("?")
                }
                else {
                    newStr.append("&")
                }
                let text = key+"="+(parameters![key] as! String)
                newStr.append(text)
                isFirst = false
            }
        }
        return newStr as String
    }
    
    func getErrorMessage(dict: NSDictionary) -> String {
        var errMsg: String = "unknown error";
        if (dict["errors"] != nil) {
            if dict["errors"] is NSDictionary {
                let errorDict: NSDictionary = dict["errors"] as! NSDictionary
                errMsg = errorDict["message"] as! String
            }
            if dict["errors"] is NSArray {
                let errors: NSArray = dict["errors"] as! NSArray
                if (errors.count > 0) {
                    if errors[0] is NSDictionary {
                        let errorDict: NSDictionary = errors[0] as! NSDictionary
                        errMsg = errorDict["message"] as! String
                    }
                }
            }
        }
        return errMsg;
    }

    public func request(urlStr: String, method: String, headers: [String: String]?, parameters: [String: Any]?, success: @escaping successBlock, failure: @escaping failureBlock) {
        let urlstr: String = getFullUrlString(urlStr: urlStr, parameters: parameters)
        print("request:\(urlstr)")
        var request: URLRequest = URLRequest.init(url: URL.init(string: urlstr)!)
        request.httpMethod = method
        if (headers != nil) {
            for key in headers!.keys {
                request.setValue(headers![key], forHTTPHeaderField: key)
            }
        }
        let session: URLSession = self.defaultURLSession
        let task = session.dataTask(with: request) { responseData, response, error in
            if (responseData != nil) {
                do {
                    let res: Any = try JSONSerialization.jsonObject(with: responseData! as Data, options: JSONSerialization.ReadingOptions(rawValue: 0))
                    print("res:\(res)")
                    let response: NSDictionary? = res as? NSDictionary
                    if (response != nil) {
                        if (response!["statusCode"] != nil) {
                            let code: Int = (response!["statusCode"] as! NSNumber).intValue
                            if (code == 200) {
                                success(response)
                            }
                            else {
                                let errMsg: String = self.getErrorMessage(dict: response!)
                                failure(code, errMsg)
                            }
                        }
                        else {
                            success(response)
                        }
                    } else {
                        let errMsg: String? = String.init(data: responseData! as Data, encoding: String.Encoding.utf8)
                        failure(400, errMsg)
                        print("responseData = \(String(describing: errMsg))")
                    }
                }
                catch {
                    print(error)
                    failure(400, "catch error")
                }
            } else {
                failure(400, "responseData is nil")
                print("responseData is nil");
            }
        }
        task.resume()
    }
    
}
