//
//  AttachmentsController.swift
//  
//
//  Created by Sam Johnson on 1/7/23.
//

import Foundation
import ImageIO
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
    
    func getAttachmentThumbnail(req: Request) throws -> Response {
        do {
            let params = try req.query.decode(AttachmentThumb.self)
            
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
            
            let absolutePath = path.replacingOccurrences(of: "~/", with: "\(FileManager.default.homeDirectoryForCurrentUser.path)/")
            
            let options: [CFString: Any] = [
                kCGImageSourceThumbnailMaxPixelSize: params.maxSize ?? 300,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            
            guard let imageSource = CGImageSourceCreateWithURL(NSURL(fileURLWithPath: absolutePath), nil),
                  let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
            else {
                req.logger.error("Unable to load image source for thumbnail generation")
                throw Abort(.internalServerError)
            }
            
            guard let imageData = CFDataCreateMutable(nil, 0),
                  let destination = CGImageDestinationCreateWithData(imageData, "public.jpeg" as CFString, 1, nil) else {
                req.logger.error("Unable to create the thumbnail image destination")
                throw Abort(.internalServerError)
            }
            
            CGImageDestinationAddImage(destination, image, nil)
            
            guard CGImageDestinationFinalize(destination) else {
                req.logger.error("Unable to write the thumbnail image to its destination")
                throw Abort(.internalServerError)
            }
            
            let res = Response()
            res.body = .init(data: imageData as Data)
            
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
        routes.get(":attachmentId", "thumb", use: getAttachmentThumbnail)
    }
}
