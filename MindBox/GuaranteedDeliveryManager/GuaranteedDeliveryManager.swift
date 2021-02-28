//
//  GuaranteedDeliveryManager.swift
//  MindBox
//
//  Created by Maksim Kazachkov on 08.02.2021.
//  Copyright © 2021 Mikhail Barilov. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import BackgroundTasks

final class GuaranteedDeliveryManager: NSObject {
    
    @Injected var databaseRepository: MBDatabaseRepository
    let backgroundTaskManager = BackgroundTaskManagerProxy()
    
    let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .background
        queue.maxConcurrentOperationCount = 1
        queue.name = "MindBox-GuaranteedDeliveryQueue"
        return queue
    }()
    
    let semaphore = DispatchSemaphore(value: 1)
    
    enum State: String, CustomStringConvertible {
        
        case idle, delivering, waitingForRetry
         
        var isDelivering: Bool {
            self == .delivering
        }
        
        var isIdle: Bool {
            self == .idle
        }
        
        var isWaitingForRetry: Bool {
            self == .waitingForRetry
        }
        
        var description: String {
            rawValue
        }
        
    }
    
    var onCompletedEvent: ((_ event: Event, _ error: ErrorModel?) -> Void)?
    
    @objc dynamic var stateObserver: NSString
    
    private(set) var state: State = .idle {
        didSet {
            stateObserver = NSString(string: state.rawValue)
            Log("State didSet to value: \(state.description)")
                .inChanel(.delivery).withType(.info).make()
        }
    }
    
    var canScheduleOperations = false {
        didSet {
            Log("canScheduleOperation didSet to value: \(canScheduleOperations)")
                .inChanel(.delivery).withType(.info).make()
            performScheduleIfNeeded()
        }
    }
    
    var fetchLimit: Int = 20
    
    init(retryDeadline: TimeInterval = 60, fetchLimit: Int = 20) {
        self.retryDeadline = retryDeadline
        self.fetchLimit = fetchLimit
        stateObserver = NSString(string: state.description)
        super.init()
        databaseRepository.onObjectsDidChange = performScheduleIfNeeded
        performScheduleIfNeeded()
        backgroundTaskManager.gdManager = self
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: nil) { [weak self] (_) in
            Log("UIApplication.didBecomeActiveNotification")
                .inChanel(.system).withType(.info).make()
            try? self?.databaseRepository.countEvents()
            self?.performScheduleIfNeeded()
        }
    }

    private let retryDeadline: TimeInterval

    func performScheduleIfNeeded() {
        guard canScheduleOperations else { return }
        let count = databaseRepository.count
        guard count != 0 else {
            backgroundTaskManager.endBackgroundTask(success: true)
            return
        }
        scheduleOperations(fetchLimit: count <= fetchLimit ? count : fetchLimit)
    }
    
    func scheduleOperations(fetchLimit: Int) {
        semaphore.wait()
        guard !state.isDelivering else {
            Log("Delivering. Ignore another schedule operation.")
                .inChanel(.delivery).withType(.info).make()
            semaphore.signal()
            return
        }
        Log("Start enqueueing events")
            .inChanel(.delivery).withType(.info).make()
        state = .delivering
        semaphore.signal()
        guard let events = try? databaseRepository.query(fetchLimit: fetchLimit, retryDeadline: retryDeadline) else {
            state = .idle
            return
        }
        guard !events.isEmpty else {
            state = .waitingForRetry
            Log("Schedule next call of performScheduleIfNeeded after TimeInterval: \(retryDeadline)")
                .inChanel(.delivery).withType(.info).make()
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + retryDeadline, execute: performScheduleIfNeeded)
            return
        }
        let completion = BlockOperation { [weak self] in
            Log("Completion of GuaranteedDelivery queue with events count \(events.count)")
                .inChanel(.delivery).withType(.info).make()
            self?.state = .idle
            self?.performScheduleIfNeeded()
        }
        let delivery = events.map {
            DeliveryOperation(event: $0)
        }
        Log("Enqueued events count: \(delivery.count)")
            .inChanel(.delivery).withType(.info).make()
        delivery.forEach {
            completion.addDependency($0)
            $0.onCompleted = onCompletedEvent
        }
        let operations = delivery + [completion]
        queue.addOperations(operations, waitUntilFinished: false)
    }
    
}

