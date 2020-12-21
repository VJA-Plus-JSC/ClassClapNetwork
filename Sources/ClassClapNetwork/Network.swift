//
//  Network.swift
//  ClassClap
//
//  Created by Quân Đinh on 09.12.19.
//  Copyright © 2019 VJA Plus. All rights reserved.
//

import UIKit

public enum NetworkError: Error {
    case badUrl
    case transportError
    case httpSeverSideError(Data, statusCode: HTTPStatus)
}

public enum HTTPStatus: Int {
    case success = 200

    case badRequest = 400
    case notAuthorized = 401
    case forbidden = 403
    case notFound = 404

    case internalServerError = 500
    
    case unknown = -1
    
    public init(_ code: Int) {
        self = HTTPStatus.init(rawValue: code) ?? .unknown
    }
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .badUrl:
            return "This seem not a vail url"
        case .transportError:
            return "There is a transport error"
        case .httpSeverSideError( _,let statusCode):
            return "There is a http server error with status code \(statusCode.rawValue)"
        }
    }
}

open class Network {
    
    /// shared instance of Network class
    public static let shared = Network()
    
    /// network handler closure
    public typealias NetworkHandler = (Result<Data, NetworkError>) -> ()
    
    /// Call a POST request. All the error handlers will stop the function immidiately
    /// - Parameters:
    ///   - urlString: plain string of the url.
    ///   - token: the bearer token
    ///   - params: http request body's parameters.
    ///   - badUrlHandler: Handling when the `urlString` is not  a vaild url.
    ///   - errorHandle: Handling when there is an error occurs with the request.
    ///   - httpErrorHandler: Handling when there is a HTTP server-side error, which the response status code is not 2xx.
    ///   - handler: Handling when successfully got the response.
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
    public func sendPostRequest(to url: String,
                                withBearerToken token: String? = nil,
                                parameters params: [String : Any?]? = nil,
                                completionHandler: @escaping NetworkHandler) {
        
        guard let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {  // encode url (to encode spaces for example)
            completionHandler(.failure(.badUrl))
            return
        }
        
        guard let url = URL(string: encodedUrl) else {
            // bad url
            completionHandler(.failure(.badUrl))
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
            if let _ = error {
                // handle transport error
                DispatchQueue.main.async {
                    completionHandler(.failure(.transportError))
                }
                return
            }
            let response = response as! HTTPURLResponse
            let responseBody = data!
            
            let statusCode = HTTPStatus(response.statusCode)
            
            if statusCode != .success {
                // handle HTTP server-side error
                if let _ = String(bytes: responseBody, encoding: .utf8) { } else {
                    // Otherwise print a hex dump of the body.
                    debugPrint("hex dump of the body")
                    debugPrint(responseBody as NSData)
                }
                
                DispatchQueue.main.async {
                    completionHandler(
                        .failure(.httpSeverSideError(responseBody, statusCode: statusCode))
                    )
                }
                return
            }
            // success handling
            DispatchQueue.main.async {
                completionHandler(.success(responseBody))
            }
        }.resume()
    }
    
}
