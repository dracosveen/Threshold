//
//  storedImage.swift
//  Threshold
//
//  Created by Martin Adolfsson on 1/27/20.
//  Copyright © 2020 Martin Adolfsson. All rights reserved.
//

import Foundation
import RealmSwift

class StoredImage: Object {
  @objc dynamic var created = String()
    @objc dynamic var filepath = ""
    @objc dynamic var distance = Float()
    
}


