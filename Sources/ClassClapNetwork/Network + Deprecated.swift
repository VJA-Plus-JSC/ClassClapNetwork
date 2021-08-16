//
//  Network + deprecated.swift
//  ClassClap
//
//  Created by Quân Đinh on 17.08.21.
//

import Foundation

// MARK: - deprecated
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
    @available(*, deprecated, message: "Decrpecated! Use sendRequest(as:,to:,authorization:,parameters:,completion:) instead")
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
            } catch {
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
    @available(*, deprecated, message: "Decrpecated! Use sendRequest(as:,to:,authorization:,parameters:,completion:) instead")
    public func sendPostRequest(
        to url: String,
        withBearerToken token: String? = nil,
        parameters params: [String : Any?]? = nil,
        completionHandler: @escaping NetworkHandler
    ) {
        sendRequest(
            as: .post,
            to: url,
            authorization: .bearerToken(token: token),
            parameters: params,
            completion: completionHandler
        )
    }
}
