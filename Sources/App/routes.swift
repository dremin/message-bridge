import Vapor

func routes(_ app: Application, db: MessagesDB, appleScriptHelper: AppleScriptHelper) throws {
    
    let messagesController = MessagesController(app, db: db, appleScriptHelper: appleScriptHelper)
    let messages = app.grouped("messages")
    
    try messages.register(collection: messagesController)
    
}
