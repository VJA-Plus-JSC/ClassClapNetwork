//
//  Network + core.swift
//  ClassClap
//
//  Created by Quân Đinh on 09.12.19.
//  Copyright © 2019 VJA Plus. All rights reserved.
//

import Foundation

open class Network {
        
    /// shared instance of Network class
    public static let shared = Network()
  
    internal let session = URLSession.shared
    
    /// network handle closure
    public typealias NetworkHandler = (Result<Data, NetworkError>) -> ()
    
    public typealias GenericResult<T: Codable> = Result<T, NetworkError>
    // network hanle generic closure
    public typealias NetworkGenericHandler<T: Codable> = (GenericResult<T>) -> ()
    
    /// private init to avoid unexpected instances allocate
    private init() {}
    
    public enum Method: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }
    
    public enum NetworkError: Error {
        case badUrl
        case transportError
        case httpSeverSideError(Data, statusCode: HTTPStatus)
        case badRequest([String: Any?])
        case jsonFormatError
        case downloadServerSideError(statusCode: HTTPStatus)
    }
    
    public enum Authorization {
        case bearerToken(token: String?)
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

extension Network.NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .badUrl:
            return "⛔️ ClassClapNetwork: This seem not a vail url."
        case .transportError:
            return "⛔️ ClassClapNetwork: There is a transport error."
        case .httpSeverSideError( _,let statusCode):
            let code = statusCode.rawValue
            return "⛔️ ClassClapNetwork: There is a http server error with status code \(code)."
        case .badRequest(let parameters):
            return "⛔️ this parameter set is invalid, check it again \n\(parameters)."
        case .jsonFormatError:
            return "⛔️ Failed in trying to decode the response body to a JSON data."
        case .downloadServerSideError(let statusCode):
            let code = statusCode.rawValue
            return "⛔️ ClassClapNetwork: There is a http server error with status code \(code)."
        }
    }
}
