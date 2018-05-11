//
//  MentionsDemoViewController.swift
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

class MentionsDemoViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet weak var textView: HKWTextView!
    @IBOutlet weak var mentionsListButton: UIButton!
    
    //
    private var plugin: HKWMentionsPlugin!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }


}

// MARK: -
extension MentionsDemoViewController {
    
    private func setupUI() {
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = UIColor.lightGray.cgColor
        // Set up the mentions system
        let mode = HKWMentionsChooserPositionMode.enclosedTop
        // In this demo, the user may explicitly begin a mention with either the '@' or '+' characters
        let controlCharacters = CharacterSet(charactersIn: "@+")
        // The user may also begin a mention by typing three characters (set searchLength to 0 to disable)
        let mentionsPlugin = HKWMentionsPlugin(chooserMode: mode,
                                               controlCharacters: controlCharacters,
                                               searchLength: 3)
        
        // NOTE: If you want to see an example of a custom chooser, uncomment the following line.
//        mentionsPlugin?.chooserViewClass = CustomChooserView.self
        
        // If the text view loses focus while the mention chooser is up, and then regains focus, it will automatically put
        //  the mentions chooser back up
        mentionsPlugin?.resumeMentionsCreationEnabled = true
        // Add edge insets so chooser view doesn't overlap the text view's cosmetic grey border
        mentionsPlugin?.chooserViewEdgeInsets = UIEdgeInsetsMake(2, 0.5, 0.5, 0.5)
        plugin = mentionsPlugin
        plugin.chooserViewBackgroundColor = .lightGray
        // The mentions plug-in requires a delegate, which provides it with mentions entities in response to a query string
        mentionsPlugin?.delegate = MentionsManager.shared
//        mentionsPlugin?.stateChangeDelegate =
        textView.controlFlowPlugin = mentionsPlugin
    }
}

// MARK: - Controls
extension MentionsDemoViewController {
    
    @IBAction func listMentionsButtonTapped(_ sender: UIButton) {
        print("There are mention(s): \(plugin.mentions().count) @% \(plugin.mentions())")
    }
    
    @IBAction func doneEditingButtonTapped(_ sender: UIButton) {
        textView.resignFirstResponder()
    }
}
