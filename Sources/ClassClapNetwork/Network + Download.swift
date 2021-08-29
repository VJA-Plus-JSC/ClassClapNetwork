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
        // TODO: https://stackoverflow.com/questions/43491880/swift-downloadtask-with-request-file-download-not-working
    }
}
