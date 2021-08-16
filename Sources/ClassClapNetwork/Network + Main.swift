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
        guard let requestResult = try? createRequest(
            from: link,
            as: method,
            authorization: authorization
        )
        else {
            return handler(.failure(.badUrl))
        }
        
        var request = requestResult.request
        let encodedUrl = requestResult.encodedUrl
        
        if let params = parameters {
            requestConfig(
                &request,
                method: method,
                encodedUrl: encodedUrl,
                parameters: params,
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
        guard let requestResult = try? createRequest(
            from: link,
            as: method,
            authorization: authorization
        )
        else {
            return handler(.failure(.badUrl))
        }
        
        var request = requestResult.request
        let encodedUrl = requestResult.encodedUrl
        
        if let params = parameters {
            requestConfig(
                &request,
                method: method,
                encodedUrl: encodedUrl,
                parameters: params,
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
