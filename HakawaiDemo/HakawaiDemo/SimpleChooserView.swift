//
//  SimpleChooserView.swift
//  HakawaiDemo
//
//  Created by Austin Zheng on 2/17/15.
//  Copyright (c) 2015 LinkedIn. All rights reserved.
//

import Foundation
import UIKit

class SimpleChooserView : UIView, UIPickerViewDataSource, UIPickerViewDelegate, HKWChooserViewProtocol {

    weak var delegate: HKWCustomChooserViewDelegate? = nil
    var borderMode : HKWChooserBorderMode = .Top

    // Protocol factory method
    @objc(chooserViewWithFrame:delegate:)
    class func chooserViewWithFrame(frame: CGRect, delegate: HKWCustomChooserViewDelegate) -> AnyObject {
        let item = NSBundle.mainBundle().loadNibNamed("SimpleChooserView", owner: nil, options: nil)[0] as! SimpleChooserView
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

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    func becomeVisible() {
        hidden = false
        setNeedsLayout()
    }

    func resetScrollPositionAndHide() {
        // Don't do anything
        hidden = true
    }

    @IBOutlet weak var pickerView: UIPickerView!

    @IBAction func chooseButtonTapped(sender: UIButton) {
        let idx = pickerView.selectedRowInComponent(0)
        delegate?.modelObjectSelectedAtIndex(idx)
    }

    // Reload the data
    func reloadData() {
        pickerView.reloadComponent(0)
    }

    // MARK: Picker view delegate and data source

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        let model = delegate?.modelObjectForIndex(row) as! HKWMentionsEntityProtocol
        return model.entityName()
    }

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return delegate?.numberOfModelObjects() ?? 0
    }
}
