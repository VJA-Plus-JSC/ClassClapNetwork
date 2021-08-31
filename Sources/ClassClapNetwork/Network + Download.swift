//
//  Network + Download.swift
//  ClassClap
//
//  Created by Quân Đinh on 29.08.21.
//

import Foundation

extension Network {
    public func downloadRequest(
        as method: Method = .post,
        to url: String,
        authorization: Authorization? = nil,
        parameters: [String : Any?]? = nil,
        completion handler: @escaping NetworkHandler
    ) {
        guard let requestResult = try? createRequest(
            from: url,
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
        
        session.downloadTask(with: request) { localTempUrl, response, error in
            /*
             - localTempUrl is the url to temporary location where the downloaded
             file is stored. This file must be handle before this call back returns.
             */
            // handle transport error
            if let _ = error {
                DispatchQueue.main.async {
                    return handler(.failure(.transportError))
                }
            }
            
            guard
                let response = response as? HTTPURLResponse
            else {
                DispatchQueue.main.async {
                    handler(.failure(.transportError))
                }
                return
            }
            
            let statusCode = HTTPStatus(response.statusCode)
            
            if case .success = statusCode {
                // handle the downloaded file
                
            } else {
                handler(.failure(.downloadServerSideError(statusCode: statusCode)))
                return
            }
        }.resume()
    }
}

typealias DownloadHandler = (Result<Data, Network.NetworkError>) -> ()
typealias ProcessHandler = (Double) -> Void

protocol DownloadTask {
    var completionHandler: DownloadHandler? { get set }
    var progressHandler: ProcessHandler? { get set }
    
    func resume()
    func suspend()
    func cancel()
}
extension Network {
    
    class GenericDownloadTask: DownloadTask {
        var completionHandler: DownloadHandler?
        var progressHandler: ProcessHandler?
        
        private(set) var task: URLSessionDataTask
        var expectedCountLenghth: Int64 = 0
        var buffer = Data()
        
        init(_ task: URLSessionDataTask) {
            self.task = task
        }
        
        deinit {
            #if DEBUG
            debugPrint("Deiniting: \(task.originalRequest?.url?.absoluteString ?? "no url")")
            #endif
        }
        
        func resume() {
            task.resume()
        }
        
        func suspend() {
            task.suspend()
        }
        
        func cancel() {
            task.cancel()
        }
    }
}

extension Network {
    
}
