//
//  Attachment.swift
//  
//
//  Created by Sam Johnson on 1/7/23.
//

import Foundation
import Vapor

struct Attachment: Content {
    var id: Int64
    var filename: String
    var path: String?
    var type: String
}
