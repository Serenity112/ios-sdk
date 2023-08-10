//
//  ViewFactoryProtocol.swift
//  Mindbox
//
//  Created by vailence on 18.07.2023.
//  Copyright © 2023 Mindbox. All rights reserved.
//

import UIKit
import Foundation

protocol ViewFactoryProtocol {
    func create(model: MindboxFormVariant,
                id: String,
                image: UIImage,
                onPresented: @escaping () -> Void,
                onTapAction: @escaping (ContentBackgroundLayerAction?) -> Void,
                onClose: @escaping () -> Void) -> UIViewController?
}
