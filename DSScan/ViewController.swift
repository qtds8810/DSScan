//
//  ViewController.swift
//  DSScan
//
//  Created by 左得胜 on 2017/9/20.
//  Copyright © 2017年 zds. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    // MARK: - Property
    private lazy var btn1: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("测试1", for: .normal)
        btn.frame = CGRect(x: 10, y: 100, width: 200, height: 40)
        btn.backgroundColor = UIColor.cyan
        btn.addTarget(self, action: #selector(btn1Click), for: .touchUpInside)
        
        return btn
    }()
    private lazy var btn2: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("测试2", for: .normal)
        btn.frame = CGRect(x: 10, y: 160, width: 200, height: 40)
        btn.backgroundColor = UIColor.cyan
        
        return btn
    }()
    
    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUI()
    }
    
    // MARK: - Action
    @objc private func btn1Click() {
        let scanVC = DSScanViewController(nibName: "DSScanViewController", bundle: Bundle.main)
        navigationController?.pushViewController(scanVC, animated: true)
    }
    
}

extension ViewController{
    
    private func setUI() {
        view.addSubview(btn1)
        view.addSubview(btn2)
    }
}

