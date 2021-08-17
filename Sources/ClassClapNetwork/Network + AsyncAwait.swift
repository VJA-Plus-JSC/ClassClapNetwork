//
//  Network + AsyncAwait.swift
//  ClassClap
//
//  Created by Quân Đinh on 17.08.21.
//

import Foundation

// MARK: - New Swift 5.5 Async await
@available(swift 5.5)
@available(iOS 15.0, *)
extension Network {
    
    /// Call a HTTP request. All the error handlers will stop the function immidiately
    /// - Parameters:
    ///   - method: HTTP method, `POST` in default
    ///   - url: plain string of the url.
    ///   - authorization: the authorization method, such as bearer token for example
    ///   - params: http request body's parameters.
    /// - Returns: Data and HTTP response.
    public func sendRequest(
        as method: Method = .post,
        to link: String,
        timeout: TimeInterval = 60.0,
        authorization: Authorization? = nil,
        parameters: [String : Any?]? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        
        // create request
        guard let requestResult = try? createRequest(
            from: link,
            as: method,
            timeout: timeout,
            authorization: authorization
        )
        else {
            throw NetworkError.badUrl
        }
        
        var request = requestResult.request
        let encodedUrl = requestResult.encodedUrl
        
        // config request
        do {
            try requestConfig(
                &request,
                method: method,
                encodedUrl: encodedUrl,
                parameters: parameters
            )
        } catch {
            throw error
        }
        
        // try to get data from request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard
            let httpResponse = response as? HTTPURLResponse,
            HTTPStatus(httpResponse.statusCode) == .success
        else {
            throw NetworkError.transportError
        }
        
        return (data, httpResponse)
    }
    
    /// Get the expected JSON - codable object via a HTTP request.
    /// - Parameters:
    ///   - method: the desired `HTTP method`.
    ///   - link: URL of the request in plain text.
    ///   - timeout: request timeout.
    ///   - authorization: The authorization of the request.
    ///   - parameters: request's parameter.
    /// - Returns: the expected JSON object.
    public func getObjectViaRequest<ObjectType: Codable>(
        as method: Method = .post,
        to link: String,
        timeout: TimeInterval = 60.0,
        authorization: Authorization? = nil,
        parameters: [String : Any?]? = nil
    ) async throws -> ObjectType {
        
        // create request
        guard let requestResult = try? createRequest(
            from: link,
            as: method,
            timeout: timeout,
            authorization: authorization
        )
        else {
            throw NetworkError.badUrl
        }
        
        var request = requestResult.request
        let encodedUrl = requestResult.encodedUrl
        
        // config request
        do {
            try requestConfig(
                &request,
                method: method,
                encodedUrl: encodedUrl,
                parameters: parameters
            )
        } catch {
            throw error
        }
        
        // try to get data from request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard
            let httpResponse = response as? HTTPURLResponse,
            HTTPStatus(httpResponse.statusCode) == .success
        else {
            throw NetworkError.transportError
        }
        
        guard let object = try? JSONDecoder().decode(ObjectType.self, from: data) else {
            throw NetworkError.jsonFormatError
        }
        
        return object
    }
}
