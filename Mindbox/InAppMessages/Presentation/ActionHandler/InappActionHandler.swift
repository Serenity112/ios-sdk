//
//  InappActionHandler.swift
//  FirebaseCore
//
//  Created by vailence on 10.08.2023.
//

import Foundation

protocol InAppActionHandlerProtocol {
    func handleAction(
        _ action: ContentBackgroundLayerAction,
        for id: String,
        onTap: @escaping InAppMessageTapAction,
        close: @escaping () -> Void
    ) -> Void
}

final class InAppActionHandler: InAppActionHandlerProtocol {
    
    private let actionUseCase: PresentationActionUseCase
    
    init(actionUseCase: PresentationActionUseCase) {
        self.actionUseCase = actionUseCase
    }
    
    func handleAction(_ action: ContentBackgroundLayerAction,
                      for id: String,
                      onTap: @escaping InAppMessageTapAction,
                      close: @escaping () -> Void) {
        switch action {
            case .redirectUrl(let redirectModel):
                actionUseCase.onTapAction(id: id,
                                          value: redirectModel.value,
                                          payload: redirectModel.intentPayload,
                                          onTap: onTap,
                                          close: close)
            case .unknown:
                return
        }
    }
}
