//
//  ExplicitManager.swift
//  Subscription
//
//  Created by Chad on 5/2/19.
//  Copyright © 2019 raizlabs. All rights reserved.
//

import Foundation

public protocol ExplicitSubscriber: AnyObject {
    func publisher(_ publisher: [DataModel])
}

