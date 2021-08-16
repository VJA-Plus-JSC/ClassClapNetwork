//
//  Network + essential.swift
//  ClassClap
//
//  Created by Quân Đinh on 17.08.21.
//

import Foundation

// MARK: - URL Request header configuration
extension Network {
    
    /// Create an `URL request` with its associated `encoded URL`.
    /// - Parameters:
    ///   - urlString: URL of the request in plain text.
    ///   - method: the desired `HTTP method`.
    ///   - timeout: request timeout.
    ///   - authorization: The authorization of the request.
    /// - Returns: a request object and its encoded URL.
    internal func createRequest(
        from urlString: String,
        as method: Method,
        timeout: TimeInterval,
        authorization: Authorization? = nil
    ) throws -> (request: URLRequest, encodedUrl: String) {
        // encode url (to encode spaces for example)
        guard
            let encodedUrl = urlString
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            throw NetworkError.badUrl
        }
        
        guard let url = URL(string: encodedUrl) else {
            // bad url
            throw NetworkError.badUrl
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
        
        return (request, encodedUrl)
    }
    
    /// configurate an `URL request` with a valid format parameters, method, etc.
    /// - Parameters:
    ///   - request: the request to config.
    ///   - method: the desired `HTTP method`.
    ///   - encodedUrl: the encoded `URL` of the request, incase it contains special charaters.
    ///   - parameters: request's parameter.
    internal func requestConfig(
        _ request: inout URLRequest,
        method: Method,
        encodedUrl: String,
        parameters: [String : Any?]? = nil
    ) throws {
        guard let parameters = parameters else {
            return
        }
        
        // only put parameter in HTTP body of a POST request, for GET, add directly to the url
        switch method {
            case .post:
                guard
                    let json = try? JSONSerialization.data(withJSONObject: parameters, options: [])
                else {
                    throw NetworkError.badRequest(parameters)
                }
                request.httpBody = json
            case .get:
                guard var finalUrl = URLComponents(string: encodedUrl) else {
                    throw NetworkError.badUrl
                }
                
                finalUrl.queryItems = parameters.map { key, value in
                    // in case value is nil, replace by blank space instead
                    URLQueryItem(name: key, value: String(describing: value ?? ""))
                }
                
                finalUrl.percentEncodedQuery = finalUrl
                    .percentEncodedQuery?
                    .replacingOccurrences(of: "+", with: "%2B")
                
                // re-assign the url with parameter components to the request
                request.url = finalUrl.url
        }
    }
    
    /// Configurate the HTTP Request body base on conditions
    /// - Parameters:
    ///   - request:the request that need to config.
    ///   - encodedUrl: plain string of the encoded url.
    ///   - parameters: http request body's parameters.
    ///   - method: HTTP method, `POST` in default.
    ///   - completion: Handling when completion, included success and failure
    internal func configRequestBody<T: Codable>(
        of request: inout URLRequest,
        encodedUrl: String,
        parameters: [String : Any?],
        method: Method,
        completion: @escaping NetworkGenericHandler<T>
    ) {
        // only put parameter in HTTP body of a POST request, for GET, add directly to the url
        switch method {
            case .post:
                do {
                    let json = try JSONSerialization.data(withJSONObject: parameters, options: [])
                    request.httpBody = json
                } catch {
                    return completion(.failure(.badRequest(parameters)))
                }
            case .get:
                guard var finalUrl = URLComponents(string: encodedUrl) else {
                    return completion(.failure(.badUrl))
                }
                
                finalUrl.queryItems = parameters.map { key, value in
                    // in case value is nil, replace by blank space instead
                    URLQueryItem(name: key, value: String(describing: value ?? ""))
                }
                
                finalUrl.percentEncodedQuery =
                finalUrl.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
                
                // re-assign the url with parameter components to the request
                request.url = finalUrl.url
        }
    }
}
