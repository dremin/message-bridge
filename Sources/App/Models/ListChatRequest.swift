//
//  ListChatRequest.swift
//  
//
//  Created by Sam Johnson on 12/20/22.
//

import Foundation
import Vapor

struct ListChatRequest: Content {
    var limit: Int?
}

// TODO: Add validator
