//
//  Network+Connectivity.swift
//  ClassClap
//
//  Created by Quân Đinh on 13.08.21.
//  Copyright © 2021 VJA Plus. All rights reserved.
//

import Network
import SystemConfiguration
import CFNetwork

extension Network {
    
    public enum ConnectionState {
        case available
        case requiresConnection
    }
    
    public class Connectivity {
        
        @available(iOSApplicationExtension 12.0, *)
        private static var monitor: NWPathMonitor? = NWPathMonitor()
        
        public static var monitorChangeHandlers = [((ConnectionState) -> Void)]() {
            didSet {
                if #available(iOSApplicationExtension 12.0, *) {
                    var newState: ConnectionState = .requiresConnection
                    // re-assign the observe events
                    monitor?.pathUpdateHandler = { path in
                        switch path.status {
                            case .satisfied:
                                newState = .available
                            case .unsatisfied:
                                newState = .requiresConnection
                            case .requiresConnection:
                                newState = .requiresConnection
                            @unknown default:
                                break
                        }
                        for handler in monitorChangeHandlers {
                            handler(newState)
                        }
                    }
                } else {
                    // TODO: add observe for network state change in iOS 11.0
                }
            }
        }
        
        static func addObserveReachabilityChange(handler: @escaping ((ConnectionState) -> Void)) {
            if #available(iOSApplicationExtension 12.0, *) {
                // start the queue if needed
                if let _ = monitor?.queue {
                    
                } else {
                    let queue = DispatchQueue(label: "Monitor")
                    monitor?.start(queue: queue)
                }
            } else {
                // TODO: set up Reachability before the first append if needed
            }
            monitorChangeHandlers.append(handler)
        }
    }
}

extension Network.Connectivity {
    
    public static func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard
            let defaultRouteReachability = withUnsafePointer(
                to:&zeroAddress,
                {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                        SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
                    }
                }
            )
        else {
            return false
        }
        
        var flags : SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
}
