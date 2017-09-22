//
//  DSScanViewController.swift
//  DSScan
//
//  Created by 左得胜 on 2017/9/21.
//  Copyright © 2017年 zds. All rights reserved.
//

import UIKit
import AVFoundation

class DSScanViewController: UIViewController {

    // MARK: - Property
    /// 扫描框
    @IBOutlet weak var scanPaneImageView: UIImageView!
    /// 提示 label
    @IBOutlet weak var tipLabel: UILabel!
    /// 转圈指示器
    @IBOutlet weak var activityIndictorView: UIActivityIndicatorView!
    /// 扫描狂的宽约束
    @IBOutlet weak var scanPaneImageViewConsW: NSLayoutConstraint!
    /// 扫描线
    private lazy var scanLineImageView: UIImageView = {
        let scanLineImageView = UIImageView(image: UIImage(named: "QRCode_ScanLine"))
        scanLineImageView.tintColor = UIColor.orange
        scanLineImageView.isHidden = true
        return scanLineImageView
    }()
    
    /// 会话
    private lazy var captureSession: AVCaptureSession = AVCaptureSession()
    /// 懒加载设备
    private lazy var device: AVCaptureDevice? = AVCaptureDevice.default(for: AVMediaType.video)
    /// 创建预览图层
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        layer.frame = self.view.layer.bounds
        return layer
    }()
    private lazy var scanPanBgLayer: CAShapeLayer = {
        let scanPanBgLayer = CAShapeLayer()
        return scanPanBgLayer
    }()
    
    /// 扫描动画时长
    private let scanAnimationDuration = 2.5
    // 这里由于xib用了自动布局（二维码宽高随之屏幕宽动态调整），自动计算frame是不对的，因此要结合xib中的约束先计算出frame
    let ivWidth = UIScreen.main.bounds.width * 0.7
    /// 标记是否扫描成功，阻止多次扫码结果拦截无效的问题
    private var isScanResultOneMore: Bool = false
    
    // MARK: - View LifeCycle
    deinit {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        previewLayer.removeFromSuperlayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        startScan()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopScan(isPlaySound: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "扫一扫"
        view.bounds = UIScreen.main.bounds
//        view.layoutSubviews()
        
        setupScan()
        setupScanPaneImageView()
        startScan()
    }
    
    // MARK: - Action
    /// 打开手电筒按钮点击
    @IBAction func lightSwitchBtnClick(_ sender: UIButton) {
        // 1.获取摄像头
        guard let captureDevice = device else {return}
        
        // 2.获取设备的控制权
        do {
            try captureDevice.lockForConfiguration()
        } catch {
            print(error)
            return
        }
        
        sender.isSelected = !sender.isSelected
        captureDevice.torchMode = (sender.isSelected ? .on : .off)
    }
    
    /// 输入车牌号按钮点击
    @IBAction func carNumberBtnClick() {
//        global_showAlert(message: "该功能暂时不能使用")
        openPhotoLibrary()
    }
    
    /// 从相册中打开二维码并识别
    private func openPhotoLibrary() {
        DSImageTool.shareInstance.choosePicture(self, isEditor: true, options: .photoLibrary) { [weak self] (image) in
            self?.activityIndictorView.startAnimating()
            
            DispatchQueue.global().async {
                // 识别图片二维码中的内容
                let recognizeResult: String?
                if #available(iOS 9, *) {
                    QL1("iOS9以上系统专用")
                    recognizeResult = image.recognizeQRCode()
                } else {
                    QL1("iOS8及其以下系统专用")
                    recognizeResult = image.recognizeQRCodeWithZXing()
                }
                
                DispatchQueue.main.async {
                    self?.activityIndictorView.stopAnimating()
                    global_showAlert(with: UIAlertControllerStyle.alert, title: "扫描结果", message: recognizeResult ?? "无法识别的二维码", confirmText: "确定", confirmHandler: nil, cancelText: nil, cancelHandler: nil)
                }
            }
        }
    }
    

}

// MARK: - Private Method
private extension DSScanViewController {
    /// 初始化扫描器
    private func setupScan() {
        
        // 设置设备输入
        guard let device = device,
            let input = try? AVCaptureDeviceInput(device: device) else {
            // 摄像头不可用
            DSImageTool.shareInstance.guideUserOpenPrivacy()
            return
        }
        
        // 判断输出能否添加到会话中
        // 设置设备输出
        guard captureSession.canAddInput(input) else {
            return
        }
        let output = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(output) else {
            return
        }
        
        // 添加输入和输出
        captureSession.addInput(input)
        captureSession.addOutput(output)
        
        // 告诉系统输出可以解析的数据类型
        // 注意点:设置可以解析数据类型一定要在输出对象添加到会话之后设置, 否则就会报错
        output.metadataObjectTypes =  output.availableMetadataObjectTypes
        
        // 5.设置代理监听解析结果
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        // 添加预览图层
        view.layer.insertSublayer(previewLayer, at: 0)
        view.layer.insertSublayer(scanPanBgLayer, above: previewLayer)
        
        activityIndictorView.stopAnimating()
        UIView.animate(withDuration: 0.25, animations: {
            self.scanPaneImageViewConsW.constant = self.ivWidth
            // 在动画过程中更新约束后更新界面只能用layoutIfNeeded()，不能用layoutSubviews()
            self.view.layoutIfNeeded()
//            self.view.layoutSubviews()
        }) { (isFinished) in
            self.scanLineImageView.frame = CGRect(x: 0, y: 0, width: self.ivWidth, height: 3)
            self.scanLineImageView.isHidden = false
            
            self.scanLineImageView.layer.add(self.scanAnimation(), forKey: "scan")
        }
        
        //设置扫描区域
        output.rectOfInterest = self.previewLayer.metadataOutputRectConverted(fromLayerRect: self.scanPaneImageView.frame)
    }
    
    /// 绘制扫描框背景
    private func setupScanPaneImageView() {
        scanPaneImageView.addSubview(scanLineImageView)
        
        let path = UIBezierPath(rect: scanPaneImageView.frame)
        path.append(UIBezierPath(rect: view.bounds))
        
        scanPanBgLayer.fillRule = kCAFillRuleEvenOdd
        scanPanBgLayer.path = path.cgPath
        scanPanBgLayer.fillColor = UIColor(white: 0, alpha: 0.6).cgColor
    }
    
    /// 开始扫描
    private func startScan() {
        DispatchQueue.global().async {
            DispatchQueue.main.async(execute: {
                self.scanLineImageView.layer.add(self.scanAnimation(), forKey: "scan")
            })
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    /// 停止扫描
    private func stopScan(isPlaySound: Bool) {
        DispatchQueue.global().async {
            if self.captureSession.isRunning {
                DispatchQueue.main.async(execute: {
                    self.scanLineImageView.layer.removeAllAnimations()
                    if isPlaySound {
                        DSImageTool.ds_playQRCodeSuccessSound(sound: "noticeMusic.caf")
                    }
                })
                self.captureSession.stopRunning()
            }
        }
    }
    
    /// 扫描动画
    private func scanAnimation() -> CABasicAnimation {
        let x = scanLineImageView.center.x
        let y = scanPaneImageView.bounds.height - 2
        
        let startPoint = CGPoint(x: x, y: 1)
        let endPoint = CGPoint(x: x, y: y)
        
        let translation = CABasicAnimation(keyPath: "position")
        translation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        translation.fromValue = NSValue(cgPoint: startPoint)
        translation.toValue = NSValue(cgPoint: endPoint)
        translation.duration = scanAnimationDuration
        translation.repeatCount = MAXFLOAT
//        translation.autoreverses = true
        
        return translation
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension DSScanViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        QL1(metadataObjects.count)
        
        // 扫描完成
        if metadataObjects.count > 0 && isScanResultOneMore == false {
            stopScan(isPlaySound: true)
            isScanResultOneMore = true
            
            if let resultObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
                let resultStr = resultObject.stringValue ?? "扫描成功，但是未能解析"
                
                print(resultStr)
                global_showAlert(message: "扫描结果：\(resultStr)", confirmHandler: { (_) in
                    self.isScanResultOneMore = false
                    self.startScan()
                })
            }
        }
    }
}
