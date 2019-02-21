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
    var borderMode : HKWChooserBorderMode = .top

    // Protocol factory method
    @objc(chooserViewWithFrame:delegate:)
    class func chooserView(withFrame frame: CGRect, delegate: HKWCustomChooserViewDelegate) -> Any {
        let item = Bundle.main.loadNibNamed("SimpleChooserView", owner: nil, options: nil)?[0] as! SimpleChooserView
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

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func becomeVisible() {
        isHidden = false
        setNeedsLayout()
    }

    func resetScrollPositionAndHide() {
        // Don't do anything
        isHidden = true
    }

    @IBOutlet weak var pickerView: UIPickerView!

    @IBAction func chooseButtonTapped(_ sender: UIButton) {
        let idx = pickerView.selectedRow(inComponent: 0)
        delegate?.modelObjectSelected(at: UInt(idx))
    }

    // Reload the data
    func reloadData() {
        pickerView.reloadComponent(0)
    }

    // MARK: Picker view delegate and data source

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let model = delegate?.modelObject(for: UInt(row)) as! HKWMentionsEntityProtocol
        return model.entityName()
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Int(delegate?.numberOfModelObjects() ?? 0)
    }
}
