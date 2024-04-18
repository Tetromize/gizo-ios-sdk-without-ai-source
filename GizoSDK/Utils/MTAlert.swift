//
//  MTAlert.swift
//  Gizo
//
//  Created by Hepburn on 2023/9/6.
//

import UIKit

class MTAlert {
    public typealias alertBlock = (_ code : String) -> ()
    
    public static func showAlertWithTitle(title: String, message: String, cancel: String?, ok: String?, clickBlock: alertBlock?, root: UIViewController? = nil) {
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        if (cancel != nil) {
            let cancelAction = UIAlertAction.init(title: cancel, style: UIAlertAction.Style.cancel) { UIAlertAction in
                clickBlock?(UIAlertAction.title!)
            }
            alertController.addAction(cancelAction)
        }
        if (ok != nil) {
            let cancelAction = UIAlertAction.init(title: ok, style: UIAlertAction.Style.default) { UIAlertAction in
                clickBlock?(UIAlertAction.title!)
            }
            alertController.addAction(cancelAction)
        }
        if (root != nil) {
            root!.present(alertController, animated: true, completion: nil)
        }
        else {
            MTAlert.currentVC().present(alertController, animated: true, completion: nil)
        }
    }
    
    public static func showAlertWithTitle(title: String, message: String) {
        MTAlert.showAlertWithTitle(title: title, message: message, cancel: "Cancel", ok: nil, clickBlock: nil, root: nil)
    }
    
    public static func showSheetWithTitle(title: String, message: String, cancel: String?, ok: [String]?, clickBlock: alertBlock?, root: UIViewController? = nil) {
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertController.Style.actionSheet)
        if (cancel != nil) {
            let cancelAction = UIAlertAction.init(title: cancel, style: UIAlertAction.Style.cancel) { UIAlertAction in
                clickBlock?(UIAlertAction.title!)
            }
            alertController.addAction(cancelAction)
        }
        if (ok != nil) {
            for name in ok! {
                let cancelAction: UIAlertAction = UIAlertAction.init(title: name, style: UIAlertAction.Style.default) { UIAlertAction in
                    clickBlock?(UIAlertAction.title!)
                }
                alertController.addAction(cancelAction)
            }
        }
        if (root != nil) {
            root!.present(alertController, animated: true, completion: nil)
        }
        else {
            MTAlert.currentVC().present(alertController, animated: true, completion: nil)
        }
        
    }
    
    public static func currentVC() -> UIViewController {
        var result: UIViewController!
        
        var window = UIApplication.shared.keyWindow
        if (window!.windowLevel != UIWindow.Level.normal) {
            let windows = UIApplication.shared.windows
            for tmpWin in windows {
                if (tmpWin.windowLevel == UIWindow.Level.normal) {
                    window = tmpWin;
                    break;
                }
            }
        }
        let frontView = window?.subviews.first
        let nextResponder = frontView?.next
        if (nextResponder!.isKind(of: UIViewController.self)) {
            result = (nextResponder as! UIViewController);
        }
        else {
            result = window!.rootViewController;
        }
        return result;
    }

}
