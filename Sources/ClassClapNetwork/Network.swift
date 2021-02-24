//
//  Network.swift
//  ClassClap
//
//  Created by Quân Đinh on 09.12.19.
//  Copyright © 2019 VJA Plus. All rights reserved.
//

import UIKit

open class Network {
    
    /// shared instance of Network class
    public static let shared = Network()
    
    /// network handler closure
    public typealias NetworkHandler = (Result<Data, NetworkError>) -> ()
    
    /// private init to avoid unexpected instances allocate
    private init() {}
    
    public enum Method: String {
        case get = "GET"
        case post = "POST"
    }
    
    public enum NetworkError: Error {
        case badUrl
        case transportError
        case httpSeverSideError(Data, statusCode: HTTPStatus)
        case badRequest([String: Any?])
    }
    
    /// Possible status code, will get raw value as 0 for the `unknown` case
    /// - 1xxs – `Informational responses`: The server is thinking through the request.
    /// - 2xxs – `Success`: The request was successfully completed and the server gave the browser the expected response.
    /// - 3xxs – `Redirection`: You got redirected somewhere else. The request was received, but there’s a redirect of some kind.
    /// - 4xxs – `Client errors`: Page not found. The site or page couldn’t be reached.
    /// (The request was made, but the page isn’t valid —
    /// this is an error on the website’s side of the conversation and often appears when a page doesn’t exist on the site.)
    /// - 5xxs – `Server errors`: Failure. A valid request was made by the client but the server failed to complete the request.
    public enum HTTPStatus: Int {
        case unknown
        
        case success = 200

        case PermanentRedirect = 301
        case TemporaryRedirect = 302
        
        case badRequest = 400
        case notAuthorized = 401
        case forbidden = 403
        case notFound = 404

        case internalServerError = 500
        case serviceUnavailable = 503
        
        public init(_ code: Int) {
            self = HTTPStatus.init(rawValue: code) ?? .unknown
        }
    }
}

extension Network {
    /// Call a POST request. All the error handlers will stop the function immidiately
    /// - Parameters:
    ///   - urlString: plain string of the url.
    ///   - token: the bearer token
    ///   - params: http request body's parameters.
    ///   - badUrlHandler: Handling when the `urlString` is not  a vaild url.
    ///   - errorHandle: Handling when there is an error occurs with the request.
    ///   - httpErrorHandler: Handling when there is a HTTP server-side error, which the response status code is not 2xx.
    ///   - handler: Handling when successfully got the response.
    @available(*, deprecated, message: "Decrpecated! Use sendRequest(as:,to:,withBearerToken:,parameters:,completion:) instead")
    public static func postRequest(
        withUrl urlString: String,
        withBearerToken token: String? = nil,
        parameters params: [String : Any?]? = nil,
        badUrlHandler: (() -> ())? = nil,
        errorHandle: ((_ error: Error) -> ())? = nil,
        httpErrorHandler: ((_ data: Data, _ statusCode: HTTPStatus) -> ())? = nil,
        success handler: ((_ data: Data) -> ())? = nil
    ) {
        guard let url = URL(string: urlString) else {
            // bad url
            if let urlHandler = badUrlHandler {
                urlHandler()
            }
            return
        }
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 60.0)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let params = params {
            do {
                let jsonParams = try JSONSerialization.data(withJSONObject: params, options: [])
                request.httpBody = jsonParams
            } catch  {
                debugPrint("Error: unable to add parameters to POST request.")
            }
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error,
               let errorHandle = errorHandle {
                // handle transport error
                DispatchQueue.main.async {
                    errorHandle(error)
                    debugPrint("There is an error: \(error.localizedDescription)")
                }
                return
            }
            let response = response as! HTTPURLResponse
            let responseBody = data!
            if !(200...299).contains(response.statusCode) {
                // handle HTTP server-side error
                if let responseString = String(bytes: responseBody, encoding: .utf8) {
                    // The response body seems to be a valid UTF-8 string, so print that.
                    debugPrint("The response body seems to be a valid UTF-8 string:")
                    debugPrint(responseString)
                } else {
                    // Otherwise print a hex dump of the body.
                    debugPrint("hex dump of the body")
                    debugPrint(responseBody as NSData)
                }
                if let httpHandler = httpErrorHandler {
                    DispatchQueue.main.async {
                        httpHandler(responseBody, HTTPStatus(response.statusCode))
                    }
                }
                return
            }
            // success handling
            if let handler = handler {
                DispatchQueue.main.async {
                    handler(responseBody)
                }
            }
        }.resume()
    }
    
    /// Call a POST request. All the error handlers will stop the function immidiately
    /// - Parameters:
    ///   - url: plain string of the url.
    ///   - token: the bearer token
    ///   - params: http request body's parameters.
    ///   - completionHandler: Handling when completion, included success and failure
    @available(*, deprecated, renamed: "sendRequest")
    public func sendPostRequest(to url: String,
                                withBearerToken token: String? = nil,
                                parameters params: [String : Any?]? = nil,
                                completionHandler: @escaping NetworkHandler) {
        
        sendRequest(as: .post,
                    to: url,
                    withBearerToken: token,
                    parameters: params,
                    completion: completionHandler)
    }
    
    /// Call a HTTP request. All the error handlers will stop the function immidiately
    /// - Parameters:
    ///   - method: HTTP method, `POST` in default
    ///   - url: plain string of the url.
    ///   - token: the bearer token
    ///   - params: http request body's parameters.
    ///   - handler: Handling when completion, included success and failure
    public func sendRequest(as method: Method = .post,
                            to link: String,
                            withBearerToken token: String? = nil,
                            parameters: [String : Any?]? = nil,
                            completion handler: @escaping NetworkHandler) {
        
        // encode url (to encode spaces for example)
        guard let encodedUrl = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            handler(.failure(.badUrl))
            return
        }
        
        guard let url = URL(string: encodedUrl) else {
            // bad url
            handler(.failure(.badUrl))
            return
        }
            
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 60.0)
        
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let params = parameters {
            // only put parameter in HTTP body of a POST request, for GET, add directly to the url
            switch method {
            case .post:
                do {
                    let jsonParams = try JSONSerialization.data(withJSONObject: params, options: [])
                    request.httpBody = jsonParams
                } catch {
                    debugPrint(
                        "ClassClapNetwork - Error: unable to add parameters to POST request."
                    )
                    return handler(.failure(.badRequest(params)))
                }
            case .get:
                guard var finalUrl = URLComponents(string: encodedUrl) else {
                    return handler(.failure(.badUrl))
                }
                finalUrl.queryItems = params.map { key, value in
                    URLQueryItem(name: key, value: value as? String)
                }
                finalUrl.percentEncodedQuery =
                    finalUrl.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")

                // re-assign the url with parameter components to the request
                request.url = finalUrl.url
            }
            
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // handle transport error
            if let _ = error {
                DispatchQueue.main.async {
                    handler(
                        .failure(.transportError)
                    )
                }
                return
            }
            
            let response = response as! HTTPURLResponse
            let responseBody = data!
            
            let statusCode = HTTPStatus(response.statusCode)
            
            if case .success = statusCode {
                // success handling
                DispatchQueue.main.async {
                    handler(.success(responseBody))
                }
            } else {
                // handle HTTP server-side error
                
                if let responseString = String(bytes: responseBody, encoding: .utf8) {
                    debugPrint(responseString)
                } else {
                    // Otherwise print a hex dump of the body.
                    debugPrint("ClassClapNetwork: hex dump of the body")
                    debugPrint(responseBody as NSData)
                }
                
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

extension Network.NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .badUrl:
            return "ClassClapNetwork: This seem not a vail url"
        case .transportError:
            return "ClassClapNetwork: There is a transport error"
        case .httpSeverSideError( _,let statusCode):
            let code = statusCode.rawValue
            return "ClassClapNetwork: There is a http server error with status code \(code)"
        case .badRequest(let parameters):
            return "this parameter set is invalid, check it again \n\(parameters)"
        }
    }
}
