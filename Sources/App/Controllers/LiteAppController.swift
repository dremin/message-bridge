//
//  LiteAppController.swift
//  
//
//  Created by Sam Johnson on 1/24/23.
//

import Foundation
import Vapor

final class LiteAppController {
    
    let defaultLimit = 20
    
    var appleScriptHelper: AppleScriptHelper
    var db: MessagesDB
    
    init(_ app: Application, db: MessagesDB, appleScriptHelper: AppleScriptHelper) {
        self.db = db
        self.appleScriptHelper = appleScriptHelper
    }
    
    func getChats(req: Request) throws -> EventLoopFuture<View> {
        do {
            let params = try req.query.decode(ListChatRequest.self)
            return req.view.render("chats", LiteChatsContext(chats: db.getRecentChats(limit: params.limit ?? defaultLimit)))
        } catch {
            req.logger.error(Logger.Message(stringLiteral: error.localizedDescription))
            throw Abort(.badRequest)
        }
    }
    
    func getChatMessages(req: Request) throws -> EventLoopFuture<View> {
        do {
            guard let chatId = req.parameters.get("chatId", as: Int.self) else {
                req.logger.error("Chat ID invalid or missing")
                throw Abort(.badRequest)
            }
            let params = try req.query.decode(ListChatRequest.self)
            
            guard let chat = db.getChat(chatId: chatId) else {
                req.logger.error("Unable to get chat")
                throw Abort(.badRequest)
            }
            
            return req.view.render("messages", LiteMessagesContext(chat: chat, messages: db.getChatMessages(chatId: chatId, limit: params.limit ?? defaultLimit)))
        } catch {
            req.logger.error(Logger.Message(stringLiteral: error.localizedDescription))
            throw Abort(.badRequest)
        }
    }
    
    func sendMessage(req: Request) throws -> EventLoopFuture<View> {
        do {
            let params = try req.content.decode(LiteSendRequest.self)
            let sendChatReq = SendChatRequest(address: params.address, isReply: true, message: params.message)
            let result = appleScriptHelper.sendMessageReply(sendChatReq)
            
            if result {
                return req.view.render("send", ["chatId": params.chatId, "rand": Int.random(in: 1..<1000)])
            } else {
                req.logger.error("Error running AppleScript to send message.")
            }
        } catch {
            req.logger.error(Logger.Message(stringLiteral: error.localizedDescription))
        }
        
        throw Abort(.badRequest)
    }
    
}

extension LiteAppController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("", use: getChats)
        
        routes.get(":chatId", use: getChatMessages)
        
        routes.post("", use: sendMessage)
    }
}
