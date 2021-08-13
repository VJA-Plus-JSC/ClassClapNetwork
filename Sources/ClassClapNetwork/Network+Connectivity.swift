//
//  Network+Connectivity.swift
//  ClassClap
//
//  Created by Quân Đinh on 13.08.21.
//  Copyright © 2021 VJA Plus. All rights reserved.
//
import Network

extension Network {
    public enum Reachability {
        case available
        case unavailabe
    }
    
    public class Connectivity {
        
        @available(iOSApplicationExtension 12.0, *)
        private static let monitor = NWPathMonitor()
        
        public static var monitorChangeHandlers = [((Reachability) -> Void)]()
        
        static func addObserveReachabilityChange(handler: @escaping ((Reachability) -> Void)) {
            if #available(iOSApplicationExtension 12.0, *) {
                if let _ = monitor.queue {
                    
                } else {
                    let queue = DispatchQueue(label: "Monitor")
                    monitor.start(queue: queue)
                }
                monitorChangeHandlers.append(handler)
                var newState: Reachability = .unavailabe
                // re-assign the observe events
                monitor.pathUpdateHandler = { path in
                    switch path.status {
                        case .satisfied:
                            newState = .available
                        case .unsatisfied:
                            newState = .unavailabe
                        case .requiresConnection:
                            break
                        @unknown default:
                            fatalError("Need to update the new case of NWPath.Status")
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
}
