//
//  BackgroundTaskManager.swift
//  MindBox
//
//  Created by Maksim Kazachkov on 15.02.2021.
//  Copyright © 2021 Mikhail Barilov. All rights reserved.
//

import Foundation
import UIKit

class BackgroundTaskManagerProxy {
    
    weak var gdManager: GuaranteedDeliveryManager? {
        didSet {
            taskManagers.forEach {
                $0.gdManager = gdManager
            }
        }
    }
        
    private var taskManagers: [BackgroundTaskManagerType] = []
    
    init() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: nil) { [weak self] (_) in
            Log("UIApplication.didEnterBackgroundNotification")
                .inChanel(.system).withType(.info).make()
            self?.taskManagers.forEach { $0.applicationDidEnterBackground() }
        }
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: nil) { [weak self] (_) in
            Log("UIApplication.didBecomeActiveNotification")
                .inChanel(.system).withType(.info).make()
            self?.gdManager?.performScheduleIfNeeded()
            self?.taskManagers.forEach { $0.applicationDidBecomeActive() }
        }
        if #available(iOS 13, *) {
            taskManagers = [UIBackgroundTaskManager(), BGTaskManager()]
        } else {
            taskManagers = [UIBackgroundTaskManager()]
        }
    }
    
    func endBackgroundTask(success: Bool) {
        taskManagers.forEach { $0.endBackgroundTask(success: success) }
    }
    
    func registerBGTasks(
        appGDRefreshIdentifier: String,
        appGDProcessingIdentifier: String,
        appDBCleanProcessingIdentifire: String
    ) {
        taskManagers.forEach {
            $0.registerBGTasks(
                appGDRefreshIdentifier: appGDRefreshIdentifier,
                appGDProcessingIdentifier: appGDProcessingIdentifier,
                appDBCleanProcessingIdentifire: appDBCleanProcessingIdentifire
            )
        }
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        taskManagers.forEach {
            $0.application(application, performFetchWithCompletionHandler: completionHandler)
        }
    }
    
}
