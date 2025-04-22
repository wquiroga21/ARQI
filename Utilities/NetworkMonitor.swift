//
//  NetworkMonitor.swift
//  SeniorProject
//
//  Created by William Quiroga on 2/26/25.
//

import Foundation
import Network
import SwiftUI

class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    @Published var isConnected = true
    @Published var showAlert = false

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.showAlert = path.status != .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
