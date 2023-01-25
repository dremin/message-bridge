//
//  HeaderMiddleware.swift
//  
//
//  Created by Sam Johnson on 12/28/22.
//

import Vapor

class HeaderMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        return next.respond(to: request).map { response in
            if response.headers.contentType == .json || response.headers.contentType == .html {
                response.headers.add(name: .cacheControl, value: "max-age=0")
            }
            return response
        }
    }

}
