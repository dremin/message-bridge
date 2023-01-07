import Vapor

func routes(_ app: Application, db: MessagesDB, appleScriptHelper: AppleScriptHelper) throws {
    
    app.get { req -> EventLoopFuture<View> in
        return req.view.render(app.directory.publicDirectory + "index.html")
    }
    
    let attachmentsController = AttachmentsController(app, db: db)
    let attachments = app.grouped("attachments")
    try attachments.register(collection: attachmentsController)
    
    let messagesController = MessagesController(app, db: db, appleScriptHelper: appleScriptHelper)
    let messages = app.grouped("messages")
    try messages.register(collection: messagesController)
    
}
