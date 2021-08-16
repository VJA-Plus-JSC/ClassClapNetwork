//
//  Network + Main.swift
//  ClassClap
//
//  Created by Quân Đinh on 17.08.21.
//

import Foundation

// MARK: - Modern fnctions
extension Network {
    
    /// Call a HTTP request. All the error handlers will stop the function immidiately
    /// - Parameters:
    ///   - method: HTTP method, `POST` in default
    ///   - url: plain string of the url.
    ///   - authorization: the authorization method, such as bearer token for example
    ///   - params: http request body's parameters.
    ///   - handler: Handling when completion, included success and failure
    public func sendRequest(
        as method: Method = .post,
        to link: String,
        authorization: Authorization? = nil,
        parameters: [String : Any?]? = nil,
        completion handler: @escaping NetworkHandler
    ) {
        
        // encode url (to encode spaces for example)
        guard let encodedUrl = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            return handler(.failure(.badUrl))
        }
        
        guard let url = URL(string: encodedUrl) else {
            // bad url
            return handler(.failure(.badUrl))
        }
        
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 60.0)
        
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // add Authorization information if has
        if let authorization = authorization {
            if case let .bearerToken(token) = authorization, let bearerToken = token {
                request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
            }
        }
        
        if let params = parameters {
            configRequestBody(
                of: &request,
                encodedUrl: encodedUrl,
                parameters: params,
                method: method,
                completion: handler
            )
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // handle transport error
            if let _ = error {
                DispatchQueue.main.async {
                    return handler(.failure(.transportError))
                }
            }
            
            guard let response = response as? HTTPURLResponse, let responseBody = data
            else {
                DispatchQueue.main.async {
                    handler(.failure(.transportError))
                }
                return
            }
            
            let statusCode = HTTPStatus(response.statusCode)
            
            if case .success = statusCode {
                /// success handling
                DispatchQueue.main.async {
                    handler(.success(responseBody))
                }
            } else {
                /// HTTP server-side error handling
                // Printout the information
                if let responseString = String(bytes: responseBody, encoding: .utf8) {
                    debugPrint(responseString)
                } else {
                    // Otherwise print a hex dump of the body.
                    debugPrint("😳 ClassClapNetwork: hex dump of the body")
                    debugPrint(responseBody as NSData)
                }
                
                // return with error handler
                DispatchQueue.main.async {
                    handler(
                        .failure(.httpSeverSideError(responseBody, statusCode: statusCode))
                    )
                }
                return
            }
        }.resume()
    }
    
    /// Call a HTTP request with expected return JSON object. All the error handlers will stop the function immidiately
    /// - Parameters:
    ///   - method: HTTP method, `POST` in default
    ///   - url: plain string of the url.
    ///   - authorization: the authorization method, such as bearer token for example
    ///   - params: http request body's parameters.
    ///   - handler: Handling when completion, included success and failure
    public func getObjectViaRequest<ObjectType: Codable>(
        as method: Method = .post,
        to link: String,
        timeout: TimeInterval = 60.0,
        authorization: Authorization? = nil,
        parameters: [String : Any?]? = nil,
        completion handler: @escaping NetworkGenericHandler<ObjectType>
    ) {
        
        // encode url (to encode spaces for example)
        guard let encodedUrl = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            return handler(.failure(.badUrl))
        }
        
        guard let url = URL(string: encodedUrl) else {
            // bad url
            return handler(.failure(.badUrl))
        }
        
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: timeout
        )
        
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // add Authorization information if has
        if let authorization = authorization {
            if case let .bearerToken(token) = authorization, let bearerToken = token {
                request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
            }
        }
        
        if let params = parameters {
            configRequestBody(
                of: &request,
                encodedUrl: encodedUrl,
                parameters: params,
                method: method,
                completion: handler
            )
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // handle transport error
            if let _ = error {
                DispatchQueue.main.async {
                    return handler(.failure(.transportError))
                }
            }
            
            guard let response = response as? HTTPURLResponse, let responseBody = data else {
                DispatchQueue.main.async {
                    handler(.failure(.transportError))
                }
                return
            }
            
            let statusCode = HTTPStatus(response.statusCode)
            
            if case .success = statusCode {
                /// success handling
                DispatchQueue.main.async {
                    //handler(.success(responseBody))
                    do {
                        let object = try JSONDecoder().decode(ObjectType.self, from: responseBody)
                        handler(.success(object))
                    } catch {
                        handler(.failure(.jsonFormatError))
                    }
                }
            } else {
                /// HTTP server-side error handling
                // Printout the information
                if let responseString = String(bytes: responseBody, encoding: .utf8) {
                    debugPrint(responseString)
                } else {
                    // Otherwise print a hex dump of the body.
                    debugPrint("😳 ClassClapNetwork: hex dump of the body")
                    debugPrint(responseBody as NSData)
                }
                
                // return with error handler
                DispatchQueue.main.async {
                    handler(
                        .failure(.httpSeverSideError(responseBody, statusCode: statusCode))
                    )
                }
                return
            }
        }.resume()
    }
}
