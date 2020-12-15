//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {
    
    static let apiKey = MyAPIKey.MyAPIKey
    
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
        case webAuth
        case logout
        case getFavorites
        case search(String)
        case markWatchlist
        case markFavorite
        case posterURL(String)
        
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .getRequestToken: return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
            case .login: return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            case .createSessionId: return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
            case .webAuth: return "https://www.themoviedb.org/authenticate/" + Auth.requestToken + "?redirect_to=themoviemanager:authenticate"
            case .logout: return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
            case .getFavorites: return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .search(let query): return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam + "&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            case .markWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .markFavorite: return Endpoints.base + "/account/\(Auth.accountId)/favorite" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .posterURL(let posterPath): return "https://image.tmdb.org/t/p/w500/" + posterPath
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, response: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(TMDBResponse.self, from: data) as Error
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        }
        task.resume()
        return task
    }
    
    class func taskForPOSTRequest<RequestType: Encodable, ResponseType: Decodable>(url: URL, body: RequestType, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?)-> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //Once the body is defined, it's encoded into a JSON object
        request.httpBody = try! JSONEncoder().encode(body)
        //After we have our JSON object, we can start a data session using the request. Swift should see the request compenents (httpMethod, addValue, body) and know what to do with it from there = once the request is sent, data is received back, which is checked for errors then decoded
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            //print(String(data: data!, encoding: .utf8)!)
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                
                //The data recieved from the request is decoded into an instance of the RequestTokenRepsonse struct
                //The the Auth.requestToken property is updated from the data recieved from the request (we should have recieved a new request token that was validated by the site/user
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let postErrorResponse = try decoder.decode(TMDBResponse.self, from: data) as Error
                    DispatchQueue.main.async {
                        completion(nil, postErrorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        //need to call this so we know the data task will be executed
        task.resume()
    }
    
    
    //Sends username and password, recieves a valid request token in return - returns True if the token is received
    class func login(username: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        let body = LoginRequest(username: username, password: password, requestToken: Auth.requestToken)
        taskForPOSTRequest(url: Endpoints.login.url, body: body, responseType: RequestTokenResponse.self) { (response, error) in
            if let response = response {
                print(Auth.requestToken + "Login")
                Auth.requestToken = response.requestToken
                completion(true, nil)
            }
            else {
                completion(false, error)
            }
        }
        
    }
    
    class func createSessionId(completion: @escaping (Bool, Error?) -> Void) {
        let body = PostSession(requestToken: Auth.requestToken)
        taskForPOSTRequest(url: Endpoints.createSessionId.url, body: body, responseType: SessionResponse.self) { response, error in
            if let response = response {
                Auth.sessionId = response.sessionId ?? ""
                completion(true, nil)
            } else {
                completion(false, error)
            }
        }
    }
    
    
    
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        taskForGETRequest(url: Endpoints.getWatchlist.url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            } else {
                completion([], nil)
            }
        }
    }

    class func getFavorites(completion: @escaping ([Movie], Error?) -> Void) {
        taskForGETRequest(url: Endpoints.getFavorites.url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
                
            } else {
                completion([], nil)
                print("getFavorites Method is NOT working")
            }
        }
    }
    
    
    class func getRequestToken(completion: @escaping (Bool, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: Endpoints.getRequestToken.url) { data, response, error in
            //print(String(data: data!, encoding: .utf8)!)
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
                DispatchQueue.main.async {
                    completion(false, error)
                }
                
            }
        }
        task.resume()
    }
    
    
    class func logout(completion: @escaping () -> Void) {
        var request = URLRequest(url: Endpoints.logout.url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = LogoutRequest(sessionId: Auth.sessionId)
        //Once the body is defined, it's encoded into a JSON object
        request.httpBody = try! JSONEncoder().encode(body)
        //After we have our JSON object, we can start a data session using the request. Swift should see the request compenents (httpMethod, addValue, body) and know what to do with it from there = once the request is sent, data is received back, which is checked for errors then decoded
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            //print(String(data: data!, encoding: .utf8)!)
            guard let data = data else {
                completion()
                return
            }
            do {
                let decoder = JSONDecoder()
                //The data recieved from the request is decoded into an instance of the RequestTokenRepsonse struct
                //The the Auth.requestToken property is updated from the data recieved from the request (we should have recieved a new request token that was validated by the site/user
                let responseObject = try decoder.decode(LogoutRequest.self, from: data)
                Auth.sessionId = ""
                Auth.requestToken = ""
                completion()
                
            }
            catch {
                print(error)
                completion()
            }
        }
        //need to call this so we know the data task will be executed
        task.resume()
    }
    
    class func search(query: String, completion: @escaping ([Movie], Error?) -> Void) -> URLSessionDataTask {
        let task = taskForGETRequest(url: Endpoints.search(query).url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            } else {
                completion([], error)
            }
        }
        return task
    }
    
    class func markWatchlist(movieId: Int, watchlist: Bool, completion: @escaping (Bool, Error?) -> Void) {
        let body = MarkWatchlist(mediaType: "movie" , mediaId: movieId, watchlist: watchlist)
        print("markWatchlist Function is called")
        TMDBClient.taskForPOSTRequest(url: Endpoints.markWatchlist.url, body: body, responseType: TMDBResponse.self) { (response, error) in
            if let response = response {
                //completion(true, nil)

                completion(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil)
                print(response)
            } else {
                completion(false, error)
                print("There is an error in the markWatchlist")
            }
        }
    }
    
    class func markFavorites(movieId: Int, favorite: Bool, completion: @escaping (Bool, Error?) -> Void) {
        let body = MarkFavorite(mediaType: "movie" , mediaId: movieId, favorite: favorite)
        print("markfavorite Function is called")
        TMDBClient.taskForPOSTRequest(url: Endpoints.markFavorite.url, body: body, responseType: TMDBResponse.self) { (response, error) in
            if let response = response {
                //completion(true, nil)
                
                completion(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil)
                print(response)
            } else {
                completion(false, error)
                print("There is an error in the markWatchlist")
            }
        }
    }
    
    class func downloadPosterImage(posterPath: String, completion: @escaping (Data?, Error?) -> Void) {
        let imageTask =  URLSession.shared.dataTask(with: Endpoints.posterURL(posterPath).url) { (data, response, error) in
            guard let data = data else {
                completion(nil, error)
                return
            }
            //var downloadedImage: UIImage? { UIImage(data: data) }
            //Returns a UIImage from the original completion handler at the top
            DispatchQueue.main.async {
            completion(data, nil)
            }
        }
        imageTask.resume()
    }
}
