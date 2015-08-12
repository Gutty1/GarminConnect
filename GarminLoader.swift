//
//  GarminLoader.swift
//  GarminConnect
//
//  Created by Arie Guttman on 8/11/15. 
//  Copyright (c) 2015 Arie Guttman. All rights reserved.
//

import Foundation



class GarminLoader {
    
    // Internal method to evaluate the Status Code of the GARMIN Response
    private func loadStatusCode (theResponse: NSURLResponse) -> Int {
        
        if let response = theResponse as? NSHTTPURLResponse {
                return response.statusCode
            } else {
                return -1
            }

    } //func loadStatusCode
    
    // Check if exist any cookie with the session enabled for our user
    func isSessionEnabledForUsername(theUsername: String) -> Bool {
        // Lets try to download the fake activity track information
        let url = NSURL(string: "http://connect.garmin.com/proxy/activity-search-service-1.2/json/activities?usename=\(theUsername)&start=0&limit=1" )
        var request = NSURLRequest(URL: url!)
        var response: NSURLResponse?
        var error: NSError?
        let responseData = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error:&error)
    
        let statusCode = loadStatusCode(response!)
        if statusCode == 403 {
                return false
        } else if (statusCode >= 200 && statusCode < 400 )
        { return true }
    
        return true
    } //func isSessionEnabledForUsername
    
//  MARK: - Garmin API methods
    
    // Enabling a new session with username/password authentication
    // The process follow the different steps according to tapiriik project
    
    func enableSessionWithUsername(theUsername: String, thePassword: String) -> Bool {
        
        let url = NSURL(string:"https://sso.garmin.com/sso/login?service=http%3A%2F%2Fconnect.garmin.com%2Fpost-auth%2Flogin&webhost=olaxpw-connect07.garmin.com&source=http%3A%2F%2Fconnect.garmin.com%2Fde-DE%2Fsignin&redirectAfterAccountLoginUrl=http%3A%2F%2Fconnect.garmin.com%2Fpost-auth%2Flogin&redirectAfterAccountCreationUrl=http%3A%2F%2Fconnect.garmin.com%2Fpost-auth%2Flogin&gauthHost=https%3A%2F%2Fsso.garmin.com%2Fsso&locale=de&id=gauth-widget&cssUrl=https%3A%2F%2Fstatic.garmincdn.com%2Fcom.garmin.connect%2Fui%2Fsrc-css%2Fgauth-custom.css&clientId=GarminConnect&rememberMeShown=true&rememberMeChecked=false&createAccountShown=true&openCreateAccount=false&usernameShown=true&displayNameShown=false&consumeServiceTicket=false&initialFocus=true&embedWidget=false")
        var request = NSMutableURLRequest(URL: url!)
        var response: NSURLResponse?
        var error: NSError?
        let responseData = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error:&error)
        let statusCode = loadStatusCode(response!)
        if statusCode != 200 {
            return false
        } else {
            // We look for the lt hidden input field
            // We will use it on the next request
            let responseString = NSString(data: responseData!, encoding: NSUTF8StringEncoding)!
            let range = NSMakeRange(0, responseString.length)
            let regex = NSRegularExpression(pattern: "name=\"lt\"\\s+value=\"([^\"]+)\"", options: NSRegularExpressionOptions.CaseInsensitive, error: nil)!
            
            let match = regex.firstMatchInString(responseString as String, options: NSMatchingOptions(0), range: range)!
            let ltContent = responseString.substringWithRange(match.rangeAtIndex(1))
            var newRequest = NSMutableURLRequest(URL: url!)
            newRequest.HTTPMethod = "POST"
            
            // Lets autenticate on the server
            let dataContent = "username=\(theUsername)&password=\(thePassword)&_eventId=submit&embed=true&lt=\(ltContent)"
            newRequest.HTTPBody = dataContent.dataUsingEncoding(NSUTF8StringEncoding)
            let newResponseData = NSURLConnection.sendSynchronousRequest(newRequest, returningResponse: &response, error:&error)
            let statusCode = loadStatusCode(response!)
            if (statusCode >= 200 && statusCode < 400) {
                if statusCode != 200 {
                    return false
                } else {
                   // We need to get the ticket "ticket=([^']+)'"
                    let responseString = NSString(data: responseData!, encoding: NSUTF8StringEncoding)!
                    let range = NSMakeRange(0, responseString.length)
                    let regex = NSRegularExpression(pattern: "ticket=([^']+)'", options: NSRegularExpressionOptions.CaseInsensitive, error: nil)!
                    
                    let match = regex.firstMatchInString(responseString as String, options: NSMatchingOptions(0), range: range)!
                    let ticket = responseString.substringWithRange(match.rangeAtIndex(1))
                    // Now we need to create a login with the received ticket
                    let url = NSURL(string:"http://connect.garmin.com/post-auth/login?ticket=\(ticket)" )
                    var request = NSMutableURLRequest(URL: url!)
                    var response: NSURLResponse?
                    var error: NSError?
                    let responseData = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error:&error)
                    let statusCode = loadStatusCode(response!)
                    if (statusCode != 302 && statusCode != 200){
                        return false
                    }
                    return true
                } //else
                
                
            } //if (statusCode >= 200 && statusCode< 400)
        } // statusCode != 200 else
    return true
    } //func enableSessionWithUsername

    // Method for donwload one sessions details
    func getSessionDetails(theSessionId: String, theURLString: String) -> String? {
        // Lets try to download the fake activity track information
        var request = NSMutableURLRequest(URL: NSURL(string: theURLString)! )
        var response: NSURLResponse?
        var error: NSError?
        let responseData = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error:&error)
        let statusCode = loadStatusCode(response!)
        if (statusCode >= 200 && statusCode < 400) {
            let responseString:NSString =  NSString(data: responseData!, encoding: NSUTF8StringEncoding)!
            return responseString as String
        }
        return nil
    }//func getSessionDetails
    
 // Short-cut to download the JSON content
    func getSessionDetails(theSessionId:String) -> String?{
        let url =  "http://connect.garmin.com/proxy/activity-service-1.3/json/activity/\(theSessionId)"
        return getSessionDetails(theSessionId, theURLString: url )
    }
   
    // Short-cut to download the TCX content
    func getSessionTCX(theSessionId:String) -> String?{
        let url =  "http://connect.garmin.com/proxy/activity-service-1.3/tcx/activity/\(theSessionId)"
        return getSessionDetails(theSessionId, theURLString: url )
    }

    // Short-cut to download the GPX content
    func getSessionGPX(theSessionId:String) -> String?{
        let url =  "http://connect.garmin.com/proxy/activity-service-1.3/gpx/activity/\(theSessionId)"
        return getSessionDetails(theSessionId, theURLString: url )
    }
  
    // Method to get the headers of the activities following the pagination
    func downloadSessionsWithOffset(theOffset: Int, theLimit:Int ) -> String? {
        // Lets try to download the fake activity track information
        let url = NSURL(string: "http://connect.garmin.com/proxy/activity-search-service-1.2/json/activities?start=\(theOffset)&limit=\(theLimit)")
        var request = NSMutableURLRequest(URL: url!)
        var response: NSURLResponse?
        var error: NSError?
        let responseData = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error:&error)
        let statusCode = loadStatusCode(response!)
        if (statusCode >= 200 && statusCode < 400) {
            let responseString:NSString =  NSString(data: responseData!, encoding: NSUTF8StringEncoding)!
            return responseString as String
        }
        return nil

    }
    
    
    
} //class GarminLoader