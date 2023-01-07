//
//  AttachmentsController.swift
//  
//
//  Created by Sam Johnson on 1/7/23.
//

import Foundation
import Vapor

final class AttachmentsController {
    
    var db: MessagesDB
    
    init(_ app: Application, db: MessagesDB) {
        self.db = db
    }
    
    func getAttachment(req: Request) throws -> Response {
        do {
            guard let attachmentId = req.parameters.get("attachmentId", as: Int.self) else {
                req.logger.error("Attachment ID invalid or missing")
                throw Abort(.badRequest)
            }
            
            guard let attachment = db.getAttachment(attachmentId: attachmentId) else {
                req.logger.error("Unable to get attachment from database")
                throw Abort(.notFound)
            }
            
            guard let path = attachment.path else {
                req.logger.error("Unable to get attachment path from database")
                throw Abort(.notFound)
            }
            
            let res = req.fileio.streamFile(at: path.replacingOccurrences(of: "~/", with: "\(FileManager.default.homeDirectoryForCurrentUser.path)/"))
            
            res.headers.add(name: .contentDisposition, value: "attachment; filename=\"\(attachment.filename)\"")
            
            return res
        } catch {
            req.logger.error(Logger.Message(stringLiteral: error.localizedDescription))
            throw Abort(.badRequest)
        }
    }
    
}

extension AttachmentsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(":attachmentId", use: getAttachment)
    }
}
