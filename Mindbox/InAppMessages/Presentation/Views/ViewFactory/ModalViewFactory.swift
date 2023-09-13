//
//  ModalViewFactory.swift
//  Mindbox
//
//  Created by vailence on 18.07.2023.
//  Copyright © 2023 Mindbox. All rights reserved.
//

import UIKit

class ModalViewFactory: ViewFactoryProtocol {
    weak var myViewController: UIViewController?
    
    func create(model: MindboxFormVariant,
                id: String,
                imagesDict: [String: UIImage],
                firstImageValue: String,
                onPresented: @escaping () -> Void,
                onTapAction: @escaping (ContentBackgroundLayerAction?) -> Void,
                onClose: @escaping () -> Void) -> UIViewController? {
        if case .modal(let modalFormVariant) = model {
            let viewController = ModalViewController(model: modalFormVariant,
                                                     id: id,
                                                     imagesDict: imagesDict,
                                                     onPresented: onPresented,
                                                     onTapAction: onTapAction,
                                                     onClose: onClose)
            myViewController = viewController
            return viewController
        }
         
        return nil
    }
}
