//
//  Attachment.swift
//  
//
//  Created by Sam Johnson on 1/7/23.
//

import Foundation
import Vapor

struct AttachmentThumb: Content {
    var maxSize: Int64?
    var download: Bool?
}
