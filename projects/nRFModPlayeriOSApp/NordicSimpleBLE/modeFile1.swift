//
//  modeFile1.swift
//  NordicSimpleBLE
//
//  Created by System Architecture on 11/12/15.
//  Copyright © 2015 Nordic Semiconductor. All rights reserved.
//

import Foundation

class modFile1 : NSObject {
    
    var data : [UInt8] = []
    
    override init() {
        super.init()
        self.data = [0x00]
    }
    
}