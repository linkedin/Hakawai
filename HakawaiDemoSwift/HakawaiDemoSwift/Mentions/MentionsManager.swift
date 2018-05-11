//
//  MentionsManager.swift
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

class MentionsManager: NSObject {

    static let shared = MentionsManager()
    
    private var fakeData = [MentionsEntity]()
    
    private func setupFakeData() {
        fakeData = [MentionsEntity(name: "Alan Perlis", id: "1"),
                     MentionsEntity(name: "Maurice Wilkes", id: "2"),
                     MentionsEntity(name: "Richard Hamming", id: "3"),
                     MentionsEntity(name: "James Wilkinson", id: "4"),
                     MentionsEntity(name: "John McCarthy", id: "5"),
                     MentionsEntity(name: "Edsger Dijkstra", id: "6"),
                     MentionsEntity(name: "Charles Bachman", id: "7"),
                     MentionsEntity(name: "Donald Knuth", id: "8"),
                     MentionsEntity(name: "Allen Newell", id: "9"),
                     MentionsEntity(name: "Herbert Simon", id: "10"),
                     MentionsEntity(name: "Michael Rabin", id: "11")
        ]
    }
}

//MARK: - HKWMentionsDelegate
extension MentionsManager: HKWMentionsDelegate {
    
    // In this method, the plug-in gives us a search string and some metadata, as well as a block. Our responsibility is to
    //  perform whatever work is necessary to get the entities for that search string (network call, database query, etc),
    //  and then to call the completion block with an array of entity objects corresponding to the search string. See the
    //  documentation for the method for more details.
    func asyncRetrieveEntities(forKeyString keyString: String!, searchType type: HKWMentionsSearchType, controlCharacter character: unichar, completion completionBlock: (([Any]?, Bool, Bool) -> Void)!) {
        if completionBlock == nil {
            return
        }
        setupFakeData()
        let data = fakeData
        var buffer = [MentionsEntity]()
        if keyString.count == 0 {
            buffer = data
        }
        else {
            for entity in data {
                let name = entity.entityName()
                if (name!.lowercased().contains(keyString.lowercased())) {
                    buffer.append(entity)
                }
            }
        }
        completionBlock(buffer, false,  true)
    }
    
    // In this method, the plug-in gives us a mentions entity (one we previously returned in response to a query), and asks
    //  us to provide a table view cell corresponding to that entity to be presented to the user.
    func cell(forMentionsEntity entity: HKWMentionsEntityProtocol!, withMatch matchString: String!, tableView: UITableView!) -> UITableViewCell! {
        var cell = tableView.dequeueReusableCell(withIdentifier: "mentionsCell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "mentionsCell")
            cell?.backgroundColor = .lightGray
        }
        cell?.textLabel?.text = entity.entityName()
        cell?.detailTextLabel?.text = entity.entityId()
        return cell
    }
    
    func heightForCell(forMentionsEntity entity: HKWMentionsEntityProtocol!, tableView: UITableView!) -> CGFloat {
        return 44
    }
    
    
}
