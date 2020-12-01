//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {
    
    static let apiKey = "7179587d60faf4f79d3952f873f04d8f"
    
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
     
        
        case getWatchlist
        case getRequestToken
        case login
        case createSessionId
        
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .getRequestToken: return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
            case .login: return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            case .createSessionId: return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    //Sends username and password, recieves a valid request token in return - returns True if the token is received
    class func login(username: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        //creates a URL Request that contains the information about the request (but isn't the actual request - the actual request is a URLSession - takes the link from the Endpoints struct and makes it a URL, then defines the different request components
        //print("Beginning of Login Function is Working")
        var request = URLRequest(url: Endpoints.login.url)
        request.httpMethod = "POST"
        request.addValue("application/JSON", forHTTPHeaderField: "Content-Type")
        //Defines the body of the request, which is a struct called Login Request, built according to the request body requirements in the API - the password and username will come from the text values entered into the view fields and stored in the LoginRequest struct. The requestToken was received with the getRequestToken function below - that's the only purpose for the function - go to that specifc URL and get a request token, which is the first step in the login process
        let body = LoginRequest(username: username, password: password, requestToken: Auth.requestToken)
        
        
        //Once the body is defined, it's encoded into a JSON object
        request.httpBody = try! JSONEncoder().encode(body)
        //After we have our JSON object, we can start a data session using the request. Swift should see the request compenents (httpMethod, addValue, body) and know what to do with it from there = once the request is sent, data is received back, which is checked for errors then decoded
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            print(String(data: data!, encoding: .utf8)!)
            
            guard let data = data else {
                completion(false, error)
                //print("No Data Recieved")
                return
            }
            do {
                let decoder = JSONDecoder()
                //print("Data is recieved by login function")
                
        //The data recieved from the request is decoded into an instance of the RequestTokenRepsonse struct
        //The the Auth.requestToken property is updated from the data recieved from the request (we should have recieved a new request token that was validated by the site/user
                print("Login Seems to Be Working Up to Decoding")
                let responseObject = try decoder.decode(RequestTokenResponse.self, from: data)
                
                Auth.requestToken = responseObject.requestToken
                print(Auth.requestToken + "Login Token")
                
                completion(true, nil)
            }
            catch {
                completion(false, error)
                print(error)
            }
        }
        //need to call this so we know the data task will be executed
        task.resume()
    }
    
    class func createSessionId(completion: @escaping (Bool, Error?) -> Void) {
        
        var request = URLRequest(url: Endpoints.createSessionId.url)
        request.httpMethod = "POST"
        request.addValue("application/JSON", forHTTPHeaderField: "Content-Type")
        let body = PostSession(requestToken: Auth.requestToken)
        //Once the body is defined, it's encoded into a JSON object
        request.httpBody = try! JSONEncoder().encode(body)
        //After we have our JSON object, we can start a data session using the request. Swift should see the request compenents (httpMethod, addValue, body) and know what to do with it from there = once the request is sent, data is received back, which is checked for errors then decoded
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            //print(String(data: data!, encoding: .utf8)!)
            guard let data = data else {
                completion(false, error)
                return
            }
            do {
                let decoder = JSONDecoder()
                //The data recieved from the request is decoded into an instance of the RequestTokenRepsonse struct
                //The the Auth.requestToken property is updated from the data recieved from the request (we should have recieved a new request token that was validated by the site/user
                let responseObject = try decoder.decode(SessionResponse.self, from: data)
                Auth.sessionId = responseObject.sessionId ?? ""
                (Auth.sessionId + "Create Session ID")
                completion(true, nil)
                
            }
            catch {
                print(error)
                completion(false, error)
            }
        }
        //need to call this so we know the data task will be executed
        task.resume()
    }

    
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: Endpoints.getWatchlist.url) { data, response, error in
            guard let data = data else {
                completion([], error)
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(MovieResults.self, from: data)
                completion(responseObject.results, nil)
            } catch {
                completion([], error)
            }
        }
        task.resume()
    }
    
    class func getRequestToken(completion: @escaping (Bool, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: Endpoints.getRequestToken.url) { data, response, error in
            guard let data = data else {
                completion(false, error)
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(RequestTokenResponse.self, from: data)
               
                Auth.requestToken = responseObject.requestToken
                completion(true, nil)
                print(Auth.requestToken + "getRequestToken")
            } catch {
                completion(false, error)
            }
        }
        task.resume()
    }
}
