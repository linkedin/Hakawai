//
//  MentionsEntity.swift
//  HakawaiDemoSwift
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

import Foundation
import Hakawai

class MentionsEntity: NSObject {

    private var name: String!
    private var id:   String!
    
    init(name: String, id: String) {
        self.name = name
        self.id = id
    }
}

extension MentionsEntity: HKWMentionsEntityProtocol {
    
    func entityId() -> String! {
        return id
    }
    
    func entityName() -> String! {
        return name
    }
    
    func entityMetadata() -> [AnyHashable : Any]! {
        return [id: name]
    }
}

