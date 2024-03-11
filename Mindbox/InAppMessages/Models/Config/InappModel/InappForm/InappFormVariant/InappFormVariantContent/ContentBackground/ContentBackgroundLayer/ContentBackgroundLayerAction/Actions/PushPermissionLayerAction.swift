//
//  PushPermissionLayerAction.swift
//  Mindbox
//
//  Created by vailence on 11.03.2024.
//  Copyright © 2024 Mindbox. All rights reserved.
//

import Foundation

struct PushPermissionLayerActionDTO: ContentBackgroundLayerActionProtocol {
    let intentPayload: String?
    let value: String?
}

struct PushPermissionLayerAction: ContentBackgroundLayerActionProtocol {
    let intentPayload: String
    let value: String
}
