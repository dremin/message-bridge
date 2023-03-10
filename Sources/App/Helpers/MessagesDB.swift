//
//  MessageDB.swift
//  MessageBridge
//
//  Created by Sam Johnson on 12/19/22.
//

import Foundation
import SQLite
import Vapor

public class MessagesDB {
    
    var app: Application
    var contactHelper: ContactHelper
    var db: Connection?
    
    init(_ app: Application, contactHelper: ContactHelper) {
        self.app = app
        self.contactHelper = contactHelper
        connect()
    }
    
    func connect() {
        do {
            db = try Connection("\(FileManager.default.homeDirectoryForCurrentUser.path)/Library/Messages/chat.db", readonly: true)
        } catch {
            app.logger.error(Logger.Message(stringLiteral: error.localizedDescription))
            app.logger.error("Did you enable Full Disk Access for this app in System Settings?")
        }
    }
    
    func parseAttributedBody(_ attributedBody: Blob) -> String {
        let bodyUnarchiver = NSUnarchiver(forReadingWith: Data.fromDatatypeValue(attributedBody))
        let bodyObject = bodyUnarchiver?.decodeObject()
        
        guard let bodyString = bodyObject else {
            app.logger.error("Unable to parse attributedBody")
            return ""
        }
        
        return sanitize(text: (bodyString as! NSAttributedString).string)
    }
    
    func sanitize(text: String) -> String {
        return text.replacingOccurrences(of: "\u{fffc}", with: "")
    }
    
    func getMessageBody(text: String?, attributedBody: Blob?, itemType: Int64, groupActionType: Int64, shareStatus: Int64) -> String {
        if text?.isEmpty ?? true {
            guard let attributedBodyBlob = attributedBody else {
                switch itemType {
                case 1:
                    if groupActionType == 0 {
                        return "Added a member to the chat"
                    } else {
                        return "Removed a member from the chat"
                    }
                case 2:
                    return "Changed the group name"
                case 3:
                    if groupActionType == 2 {
                        return "Removed the group photo"
                    } else {
                        return "Changed the group photo"
                    }
                case 4:
                    if shareStatus == 0 {
                        return "Started sharing location"
                    } else {
                        return "Stopped sharing location"
                    }
                default:
                    app.logger.error("Missing both text and attributedBody")
                    return ""
                }
            }
            
            return parseAttributedBody(attributedBodyBlob)
        } else {
            return sanitize(text: text!)
        }
    }
    
    func parseChat(row: Statement.Element) -> Chat {
        let chatId = row[0] as? Int64
        let address = row[1] as? String
        let displayName = row[2] as? String
        let attributedBody = row[3] as? Blob
        let text = row[4] as? String
        let lastReceived = row[5] as? String
        let service = row[6] as? String
        let replyId = row[7] as? String
        let itemType = row[8] as? Int64
        let groupActionType = row[9] as? Int64
        let shareStatus = row[10] as? Int64
        
        var chat = Chat(id: chatId ?? 0, replyId: replyId ?? "", name: "Unknown", lastMessage: "N/A", lastReceived: lastReceived ?? "N/A", service: service ?? "iMessage")
        
        if !(displayName?.isEmpty ?? true) {
            chat.name = displayName!
        } else if !(address?.isEmpty ?? true) {
            chat.name = contactHelper.parseAddress(address!)
        }
        
        chat.lastMessage = getMessageBody(text: text, attributedBody: attributedBody, itemType: itemType ?? 0, groupActionType: groupActionType ?? 0, shareStatus: shareStatus ?? 0)
        
        return chat
    }
    
    func getRecentChats(limit: Int) -> [Chat] {
        if db == nil {
            connect()
        }
        
        guard let messagesDb = db else {
            app.logger.error("No database connection")
            return []
        }
        
        do {
            var chats: [Chat] = []
            
            for row in try messagesDb.run("""
select cmj.chat_id,
group_concat(distinct h.id) as address,
c.display_name,
m.attributedBody,
m.text,
datetime(m.date/1000000000 + 978307200,'unixepoch','localtime') as lastReceived,
c.service_name,
c.guid as replyId,
m.item_type,
m.group_action_type,
m.share_status,
Max(m.date)
from chat as c
inner join chat_message_join as cmj on cmj.chat_id = c.ROWID
inner join message as m on cmj.message_id = m.ROWID
inner join chat_handle_join as chj on chj.chat_id = c.ROWID
inner join handle as h on chj.handle_id = h.ROWID
group by cmj.chat_id
order by m.date desc
limit ?
""", limit) {
                chats.append(parseChat(row: row))
            }
            
            return chats
        } catch {
            app.logger.error(Logger.Message(stringLiteral: error.localizedDescription))
            return []
        }
    }
    
    func getChat(chatId: Int) -> Chat? {
        if db == nil {
            connect()
        }
        
        guard let messagesDb = db else {
            app.logger.error("No database connection")
            return nil
        }
        
        do {
            var chats: [Chat] = []
            
            for row in try messagesDb.run("""
select cmj.chat_id,
group_concat(distinct h.id) as address,
c.display_name,
m.attributedBody,
m.text,
datetime(m.date/1000000000 + 978307200,'unixepoch','localtime') as lastReceived,
c.service_name,
c.guid as replyId,
m.item_type,
m.group_action_type,
m.share_status,
Max(m.date)
from chat as c
inner join chat_message_join as cmj on cmj.chat_id = c.ROWID
inner join message as m on cmj.message_id = m.ROWID
inner join chat_handle_join as chj on chj.chat_id = c.ROWID
inner join handle as h on chj.handle_id = h.ROWID
group by cmj.chat_id
having cmj.chat_id = ?
""", chatId) {
                chats.append(parseChat(row: row))
            }
            
            if chats.count > 0 {
                return chats[0]
            }
            
            return nil
        } catch {
            app.logger.error(Logger.Message(stringLiteral: error.localizedDescription))
            return nil
        }
    }
    
    func getChatMessages(chatId: Int, limit: Int) -> [ChatMessage] {
        if db == nil {
            connect()
        }
        
        guard let messagesDb = db else {
            app.logger.error("No database connection")
            return []
        }
        
        do {
            var messages: [ChatMessage] = []
            
            for row in try messagesDb.run("""
select cmj.chat_id,
cmj.message_id,
h.id as address,
m.is_from_me,
m.attributedBody,
m.text,
datetime(m.date/1000000000 + 978307200,'unixepoch','localtime') as received,
group_concat(a.ROWID, '|') as attachment_ids,
group_concat(a.transfer_name, '|') as attachment_names,
group_concat(a.mime_type, '|') as attachment_types,
m.item_type,
m.group_action_type,
m.share_status
from message as m
inner join chat_message_join as cmj on cmj.message_id = m.ROWID
left join handle as h on m.handle_id = h.ROWID
left join message_attachment_join as maj on maj.message_id = m.ROWID
left join attachment as a on maj.attachment_id = a.ROWID and a.hide_attachment != 1
where cmj.chat_id = ?
group by m.ROWID
order by m.date desc
limit ?
""", chatId, limit) {
                let chatId = row[0] as? Int64
                let messageId = row[1] as? Int64
                let address = row[2] as? String
                let isMe = row[3] as? Int64
                let attributedBody = row[4] as? Blob
                let text = row[5] as? String
                let received = row[6] as? String
                let attachmentIds = row[7] as? String
                let attachmentNames = row[8] as? String
                let attachmentTypes = row[9] as? String
                let itemType = row[10] as? Int64
                let groupActionType = row[11] as? Int64
                let shareStatus = row[12] as? Int64
                
                var message = ChatMessage(id: messageId ?? 0, chatId: chatId ?? 0, from: "Unknown", isMe: isMe == 1, body: "", received: received ?? "N/A")
                
                if !(address?.isEmpty ?? true) {
                    message.from = contactHelper.parseAddress(address!)
                }
                
                message.body = getMessageBody(text: text, attributedBody: attributedBody, itemType: itemType ?? 0, groupActionType: groupActionType ?? 0, shareStatus: shareStatus ?? 0)
                
                if !(attachmentIds?.isEmpty ?? true) && !(attachmentNames?.isEmpty ?? true) && !(attachmentTypes?.isEmpty ?? true) {
                    var attachments: [Attachment] = []
                    
                    let attachmentIdArr = attachmentIds!.split(separator: "|")
                    let attachmentNameArr = attachmentNames!.split(separator: "|")
                    let attachmentTypeArr = attachmentTypes!.split(separator: "|")
                    
                    if attachmentNameArr.count >= attachmentIdArr.count && attachmentTypeArr.count >= attachmentIdArr.count {
                        for attachmentNum in 0..<attachmentIdArr.count {
                            guard let attachmentId = Int64(attachmentIdArr[attachmentNum]) else {
                                continue
                            }
                            
                            attachments.append(Attachment(id: attachmentId, filename: String(attachmentNameArr[attachmentNum]), type: String(attachmentTypeArr[attachmentNum])))
                        }
                        
                        message.attachments = attachments
                    }
                }
                
                messages.append(message)
            }
            
            return messages
        } catch {
            app.logger.error(Logger.Message(stringLiteral: error.localizedDescription))
            return []
        }
    }
    
    func getAttachment(attachmentId: Int) -> Attachment? {
        if db == nil {
            connect()
        }
        
        guard let messagesDb = db else {
            app.logger.error("No database connection")
            return nil
        }
        
        do {
            for row in try messagesDb.run("""
select transfer_name, filename, mime_type
from attachment
where ROWID = ?
limit 1
""", attachmentId) {
                let filename = row[0] as? String
                let path = row[1] as? String
                let type = row[2] as? String
                
                return Attachment(id: Int64(attachmentId), filename: filename ?? "Attachment", path: path ?? "Unknown", type: type ?? "Unknown")
            }
            
            return nil
        } catch {
            app.logger.error(Logger.Message(stringLiteral: error.localizedDescription))
            return nil
        }
    }
}
