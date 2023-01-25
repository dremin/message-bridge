import Vapor

func routes(_ app: Application, db: MessagesDB, appleScriptHelper: AppleScriptHelper) throws {
    
    app.get { req -> EventLoopFuture<View> in
        return req.view.render(app.directory.publicDirectory + "index.html")
    }
    
    let attachmentsController = AttachmentsController(app, db: db)
    let attachments = app.grouped("attachments")
    try attachments.register(collection: attachmentsController)
    
    let chatsController = ChatsController(app, db: db, appleScriptHelper: appleScriptHelper)
    let chats = app.grouped("chats")
    try chats.register(collection: chatsController)
    
    let liteAppController = LiteAppController(app, db: db, appleScriptHelper: appleScriptHelper)
    let liteApp = app.grouped("lite")
    try liteApp.register(collection: liteAppController)
    
}
