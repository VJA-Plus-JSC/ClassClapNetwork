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
        private static var monitor: NWPathMonitor? = NWPathMonitor()
        
        public static var monitorChangeHandlers = [((Reachability) -> Void)]() {
            didSet {
                if #available(iOSApplicationExtension 12.0, *) {
                    var newState: Reachability = .unavailabe
                    // re-assign the observe events
                    monitor?.pathUpdateHandler = { path in
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
        
        static func addObserveReachabilityChange(handler: @escaping ((Reachability) -> Void)) {
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
        
        static func connectivityMonitorSetup() {
            if #available(iOSApplicationExtension 12.0, *) {
                monitor = nil
            } else {
                // TODO: Reachability object will be nil
            }
        }
    }
}
