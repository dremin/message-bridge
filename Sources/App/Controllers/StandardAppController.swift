//
//  StandardAppController.swift
//  
//
//  Created by Sam Johnson on 1/25/23.
//

import Foundation
import Vapor

final class StandardAppController {
    
    init(_ app: Application) {
    }
    
    func getIndex(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("standard")
    }
    
}

extension StandardAppController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("", use: getIndex)
        routes.get("index.htm", use: getIndex)
        routes.get("index.html", use: getIndex)
    }
}
