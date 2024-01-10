//
//  ChatsController.swift
//  
//
//  Created by Sam Johnson on 12/20/22.
//

import Foundation
import Vapor

final class ChatsController {
    
    var appleScriptHelper: AppleScriptHelper
    var db: MessagesDB
    
    init(_ app: Application, db: MessagesDB, appleScriptHelper: AppleScriptHelper) {
        self.db = db
        self.appleScriptHelper = appleScriptHelper
    }
    
    func getChats(req: Request) throws -> [Chat] {
        do {
            let params = try req.query.decode(ListChatRequest.self)
            return db.getRecentChats(limit: params.limit ?? 5)
        } catch {
            req.logger.error(Logger.Message(stringLiteral: error.localizedDescription))
            throw Abort(.badRequest)
        }
    }
    
    func getChatMessages(req: Request) throws -> [ChatMessage] {
        do {
            guard let chatId = req.parameters.get("chatId", as: Int.self) else {
                req.logger.error("Chat ID invalid or missing")
                throw Abort(.badRequest)
            }
            let params = try req.query.decode(ListChatRequest.self)
            return db.getChatMessages(chatId: chatId, limit: params.limit ?? 5)
        } catch {
            req.logger.error(Logger.Message(stringLiteral: error.localizedDescription))
            throw Abort(.badRequest)
        }
    }
    
    func sendMessage(req: Request) -> HTTPStatus {
        do {
            let params = try req.content.decode(SendChatRequest.self)
            var result = false
            
            if params.isReply {
                result = appleScriptHelper.sendMessageReply(params)
                
                if !result {
                    // fall back to sending as a new chat
                    // we need to extract the service from the reply address
                    let splitAddress = params.address.split(separator: ";")
                    if splitAddress.count > 1 {
                        let newParams = SendChatRequest(
                            address: String(splitAddress[splitAddress.count - 1]),
                            isReply: false,
                            service: String(splitAddress[0]),
                            message: params.message)
                        result = appleScriptHelper.sendMessage(newParams)
                        req.logger.info("Sent reply as a new chat due to a Messages error.")
                    }
                }
            } else {
                result = appleScriptHelper.sendMessage(params)
            }
            
            if result {
                return HTTPStatus.ok
            } else {
                req.logger.error("Error running AppleScript to send message.")
            }
        } catch {
            req.logger.error(Logger.Message(stringLiteral: error.localizedDescription))
        }
        
        return HTTPStatus.badRequest
    }
    
}

extension ChatsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("", use: getChats)
        
        routes.get(":chatId", "messages", use: getChatMessages)
        
        routes.post("", use: sendMessage)
    }
}
