//
//  AppleScriptHelper.swift
//
//
//  Created by Sam Johnson on 12/22/22.
//

import Foundation
import Contacts
import Vapor

public class AppleScriptHelper {
    
    var app: Application
    
    init(_ app: Application) {
        self.app = app
    }
    
    func runScript(_ script: String) -> Bool {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let _: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error)
            
            if error == nil {
                return true
            } else {
                app.logger.error("Error executing AppleScript: \(String(describing: error))")
            }
        } else {
            app.logger.error("Error initializing AppleScript")
        }
        return false
    }
    
    func launchMessages() {
        var script: String
        
        if #available(macOS 11.0, *) {
            script = """
                tell application "Messages"
                    login
                end tell
                """
        } else {
            script = """
                tell application "Messages"
                    log in
                end tell
                """
        }
        
        if (!runScript(script)) {
            app.logger.error("Error running AppleScript to launch Messages.")
        }
    }
    
    func sendMessage(_ params: SendChatRequest) -> Bool {
        var script: String
        
        if #available(macOS 11.0, *) {
            script = """
                tell application "Messages"
                    set targetBuddy to "\(params.address)"
                    set targetService to id of 1st account whose service type = \(params.service)
                    set textMessage to "\(params.message.replacingOccurrences(of: "\"", with: "\\\""))"
                    set theBuddy to participant targetBuddy of account id targetService
                    send textMessage to theBuddy
                end tell
                """
        } else {
            script = """
                tell application "Messages"
                    set targetBuddy to "\(params.address)"
                    set targetService to id of 1st service whose service type = \(params.service)
                    set textMessage to "\(params.message.replacingOccurrences(of: "\"", with: "\\\""))"
                    set theBuddy to buddy targetBuddy of service id targetService
                    send textMessage to theBuddy
                end tell
                """
        }
        
        if (runScript(script)) {
            return true
        } else {
            app.logger.error("Error running AppleScript to send message.")
            return false
        }
    }
    
}
