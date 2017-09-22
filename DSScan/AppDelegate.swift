//
//  AppDelegate.swift
//  DSScan
//
//  Created by 左得胜 on 2017/9/20.
//  Copyright © 2017年 zds. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.white
        
        let vc = ViewController()
        let nav = UINavigationController(rootViewController: vc)
        window?.rootViewController = nav
        
        window?.makeKeyAndVisible()
        return true
    }

    
}

// MARK: - 获取最顶层的ViewController
func global_getTopViewController() -> UIViewController? {
    var resultVC: UIViewController?
    if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
        resultVC = getTopVC(rootVC)
        while resultVC?.presentedViewController != nil {
            resultVC = resultVC?.presentedViewController
        }
    }
    return resultVC
}

private func getTopVC(_ object: AnyObject?) -> UIViewController? {
    if let navVC = object as? UINavigationController {
        return getTopVC(navVC.viewControllers.last)
    } else if let tabBarVC = object as? UITabBarController {
        if tabBarVC.selectedIndex < tabBarVC.viewControllers!.count {
            return getTopVC(tabBarVC.viewControllers![tabBarVC.selectedIndex])
        }
    } else if let vc = object as? UIViewController {
        return vc
    }
    return nil
}
//MARK: - 全局展示警告框
func global_showAlert(with preferredStyle: UIAlertControllerStyle = UIAlertControllerStyle.alert, title: String? = nil, message: String?, confirmText: String? = "确定", confirmHandler: ((UIAlertAction) -> Void)? = nil, cancelText: String? = nil, cancelHandler: ((UIAlertAction) -> Void)? = nil){
    let alertVC = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
    if cancelText != nil {
        alertVC.addAction(UIAlertAction(title: cancelText, style: UIAlertActionStyle.cancel, handler: cancelHandler))
    }
    if confirmText != nil {
        alertVC.addAction(UIAlertAction(title: confirmText, style: UIAlertActionStyle.default, handler: confirmHandler))
    }
    global_getTopViewController()?.present(alertVC, animated: true, completion: nil)
}

// MARK: - 自定义打印信息
func QL1<T>(_ debug: T, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    //    if isLogUnEnabled == false {
    #if DEBUG
        print("\((file as NSString).pathComponents.last!):\(line) \(function): \(debug)")
    #endif
    //    }
}
