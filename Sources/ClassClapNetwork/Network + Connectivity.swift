//
//  Network + Connectivity.swift
//  ClassClap
//
//  Created by Quân Đinh on 13.08.21.
//  Copyright © 2021 VJA Plus. All rights reserved.
//

import Network
import SystemConfiguration

extension Network {
    
    public enum ConnectionState {
        case available
        case requiresConnection
    }
    
    @available(macOS 10.14, *)
    public class Connectivity {
        // https://www.hackingwithswift.com/example-code/networking/how-to-check-for-internet-connectivity-using-nwpathmonitor
        @available(iOSApplicationExtension 12.0, *)
        @available(iOS 12.0, *)
        private static var monitor: NWPathMonitor? = NWPathMonitor()
    }
}

@available(macOS 10.14, *)
extension Network.Connectivity {
    
    public static func isNetworkReacability() -> Bool {
        if #available(iOSApplicationExtension 12.0, iOS 12.0, *) {
            guard
                // if there are no interfaces, the current path is none.
                let monitor = monitor, monitor.currentPath.availableInterfaces.count > 0
            else {
                return false
            }
            return monitor.currentPath.status == .satisfied
        } else {
            return isReachability()
        }
    }
    
    /// Check reachability in iOS lower than 12
    /// - Returns: is Network status reachability or not
    private static func isReachability() -> Bool {
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

// TODO: Working with the observation scenarios here in the future
/*
 some possible references:
 - https://stackoverflow.com/questions/30743408/check-for-internet-connection-with-swift
 - https://github.com/ashleymills/Reachability.swift
 */
#if DEBUG
@available(macOS 10.14, *)
extension Network.Connectivity {
    
    public static var monitorChangeHandlers = [((Network.ConnectionState) -> Void)]() {
        didSet {
            if #available(iOSApplicationExtension 12.0, iOS 12.0, *) {
                var newState: Network.ConnectionState = .requiresConnection
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
    
    static func addObserveReachabilityChange(
        handler: @escaping ((Network.ConnectionState) -> Void)
    ) {
        if #available(iOSApplicationExtension 12.0, iOS 12.0, *) {
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
#endif
