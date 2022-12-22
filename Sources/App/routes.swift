import Vapor

func routes(_ app: Application) throws {
    /*app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }*/
    
    let messagesController = MessagesController(app)
    let messages = app.grouped("messages")
    
    try messages.register(collection: messagesController)
    
}
