//
//  DSImageTool.swift
//  12-QRCode
//
//  Created by 左得胜 on 2016/12/30.
//  Copyright © 2016年 左得胜. All rights reserved.
//

import UIKit
import AudioToolbox
import AssetsLibrary
import AVFoundation

struct PhotoSource: OptionSet {
    let rawValue: Int
    static let camera = PhotoSource(rawValue: 1)
    static let photoLibrary = PhotoSource(rawValue: 1<<1)
}

class DSImageTool: NSObject {
    /// 单例
    static let shareInstance: DSImageTool = DSImageTool()
    private override init() {}
    /// 定义闭包别名
    typealias finishedImageClosure = ((_ image: UIImage) -> Void)
    
    /// 选择之后的闭包传值
    var finishedImg: finishedImageClosure?
    /// 是否允许编辑
    var isEditor = false
    
    /// 弹框供用户选择
    ///
    /// - Parameters:
    ///   - controller: 传入控制器
    ///   - isEditor: 是否允许编辑
    ///   - options: 相机还是相册
    ///   - finished: 完成之后闭包
    func choosePicture(_ controller: UIViewController, isEditor: Bool, options: PhotoSource = [.camera, .photoLibrary], finished: @escaping finishedImageClosure) {
        self.finishedImg = finished
        self.isEditor = isEditor
        
        if options.contains(.camera) && options.contains(.photoLibrary) {
            let alertController = UIAlertController(title: "请选择图片", message: nil, preferredStyle: .actionSheet)
            
            alertController.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "从相册选取", style: UIAlertActionStyle.default, handler: { [weak self] (action) in
                self?.setupPhotoLibrary(controller: controller, isEditor: isEditor)
            }))
            alertController.addAction(UIAlertAction(title: "拍照", style: UIAlertActionStyle.default, handler: { (action) in
                self.setupCamera(controller: controller, isEditor: isEditor)
            }))
            
            controller.present(alertController, animated: true, completion: nil)
        } else if options.contains(.photoLibrary) {
            self.setupPhotoLibrary(controller: controller, isEditor: isEditor)
        } else if options.contains(.camera) {
            setupCamera(controller: controller, isEditor: isEditor)
        }
    }
    
    /// 打开相机
    private func setupCamera(controller: UIViewController, isEditor: Bool) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            guideUserOpenPrivacy()
            return
        }
        
        guard isCanUseCameraPrivacy() else {
            guideUserOpenPrivacy()
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.allowsEditing = isEditor
//        picker.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        controller.present(picker, animated: true, completion: nil)
    }
    
    /// 打开相册
    private func setupPhotoLibrary(controller: UIViewController, isEditor: Bool) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            guideUserOpenPrivacy()
            return
        }
        
        guard isCanUsePhotoLibraryPrivacy() else {
            guideUserOpenPrivacy()
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = isEditor
//        picker.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        controller.present(picker, animated: true, completion: nil)
    }
    
    // MARK: - Public Method
    /// 检测用户是否允许APP使用者相册权限
    func isCanUsePhotoLibraryPrivacy() -> Bool {
        let authStatus = ALAssetsLibrary.authorizationStatus()
        switch authStatus {
        case .authorized, .notDetermined:
            return true
        case .denied, .restricted:
            return false
        }
    }
    
    /// 检测用户是否允许APP使用者相机权限
    func isCanUseCameraPrivacy() -> Bool {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authStatus {
        case .authorized, .notDetermined:
            return true
        case .denied, .restricted:
            return false
        }
    }
    
    /// 引导用户打开使用权限
    func guideUserOpenPrivacy() {
        global_showAlert(with: UIAlertControllerStyle.alert, title: "无法访问相机或照片", message: "请到系统的隐私设置中，允许加油助手访问“相机”和“照片”。", confirmText: "设置", confirmHandler: { (action) in
            if UIApplication.shared.canOpenURL(URL(string: UIApplicationOpenSettingsURLString)!) {
                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            }
        }, cancelText: "好", cancelHandler: nil)
        
    }
    
    /// 播放声音
    class func ds_playQRCodeSuccessSound(sound: String) {
        guard let soundPath = Bundle.main.path(forResource: sound, ofType: nil)  else { return }
        guard let soundUrl = NSURL(string: soundPath) else { return }
        
        var soundID:SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundUrl, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension DSImageTool: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[isEditor ? UIImagePickerControllerEditedImage : UIImagePickerControllerOriginalImage] as? UIImage else {
            
            return
        }
        
        picker.dismiss(animated: true) { [weak self] in
            self?.finishedImg?(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

