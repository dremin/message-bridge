import Vapor
import Leaf

// configures your application
public func configure(_ app: Application) throws {
    // MARK: Middleware
    // serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // apply standard headers
    app.middleware.use(HeaderMiddleware())
    // Leaf templating is used for the Lite app
    app.views.use(.leaf)
    
    // MARK: Init helpers
    let appleScriptHelper = AppleScriptHelper(app)
    let contactHelper = ContactHelper(app)
    let messagesDb = MessagesDB(app, contactHelper: contactHelper)
    
    // MARK: Request user permissions
    // Messages scripting permission via launching it
    appleScriptHelper.launchMessages()
    // Contacts permission
    contactHelper.requestPermission()

    // register routes
    try routes(app, db: messagesDb, appleScriptHelper: appleScriptHelper)
}
