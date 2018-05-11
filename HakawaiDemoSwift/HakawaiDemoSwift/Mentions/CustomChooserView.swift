//
//  CustomChooserView.swift
//  HakawaiDemoSwift
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

import UIKit
import Hakawai

class CustomChooserView: UIView {
    
    @IBOutlet weak var pickerView: UIPickerView!

    weak var delegate: HKWCustomChooserViewDelegate?
    var borderMode: HKWChooserBorderMode = .top
    
    // Protocol factory method
    @objc(chooserViewWithFrame:delegate:)
    class func chooserView(withFrame frame: CGRect, delegate: HKWCustomChooserViewDelegate) -> Any {
        let item = Bundle.main.loadNibNamed("CustomChooserView", owner: nil, options: nil)?[0] as! CustomChooserView
        item.delegate = delegate
        item.frame = frame
        item.setNeedsLayout()
        return item
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        pickerView.dataSource = self
        pickerView.delegate = self
    }
}

// MARK: - HKWChooserViewProtocol
extension CustomChooserView: HKWChooserViewProtocol {
    func becomeVisible() {
        isHidden = false
        setNeedsLayout()
    }
    
    func resetScrollPositionAndHide() {
        // Don't do anything
        isHidden = true
    }
    
    func reloadData() {
        pickerView.reloadComponent(0)
    }
    
    
}

// MARK: - UIPickerViewDataSource
extension CustomChooserView: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return delegate?.numberOfModelObjects() ?? 0
    }
}

//MARK: - UIPickerViewDelegate
extension CustomChooserView: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let model = delegate?.modelObject(for: row) as! HKWMentionsEntityProtocol
        return model.entityName()
    }
}

// MARK: - Controls
extension CustomChooserView {
    
    @IBAction func chooseButtonTapped(_ sender: UIButton) {
        let idx = pickerView.selectedRow(inComponent: 0)
        delegate?.modelObjectSelected(at: idx)
    }
}
