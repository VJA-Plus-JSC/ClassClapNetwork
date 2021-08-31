//
//  Network + Download.swift
//  ClassClap
//
//  Created by Quân Đinh on 29.08.21.
//

import Foundation

protocol DownloadTask {
    var completionHandler: Network.DownloadHandler? { get set }
    var progressHandler: Network.ProcessHandler? { get set }
    
    func resume()
    func suspend()
    func cancel()
}

extension Network {
    typealias DownloadHandler = (Result<Data, Error>) -> ()
    typealias ProcessHandler = (Double) -> Void

    class GenericDownloadTask: DownloadTask {
        var completionHandler: DownloadHandler?
        var progressHandler: ProcessHandler?
        
        private(set) var task: URLSessionDataTask
        var expectedContentLength: Int64 = 0
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
    final class DownloadQueue: NSObject {
        private var session: URLSession!
        private var queue: [GenericDownloadTask] = []
        
        public static let shared = DownloadQueue()
        
        private override init() {
            super.init()
            let configuration = URLSessionConfiguration.default
            session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        }
        
        func download(request: URLRequest) -> DownloadTask {
            let task = self.session.dataTask(with: request)
            let downloadTask = GenericDownloadTask(task)
            queue.append(downloadTask)
            return downloadTask
        }
    }
}

extension Network.DownloadQueue: URLSessionDataDelegate {
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        guard let task = queue.first(where: { $0.task == dataTask }) else {
            completionHandler(.cancel)
            return
        }
        task.expectedContentLength = response.expectedContentLength
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let task = queue.first(where: { $0.task == dataTask }) else {
            return
        }
        task.buffer.append(data)
        let percentage = Double(task.buffer.count) / Double(task.expectedContentLength)
        
        DispatchQueue.main.async {
            task.progressHandler?(percentage)
        }
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let index = queue.firstIndex(where: { $0.task == task }) else {
            return
        }
        
        let task = queue.remove(at: index)
        DispatchQueue.main.async {
            guard let error = error else {
                task.completionHandler?(.success(task.buffer))
                return
            }
            task.completionHandler?(.failure(error))
        }
    }
}
