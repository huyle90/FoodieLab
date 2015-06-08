//
//  CGSize.swift
//  FoodieLab
//
//  Created by Huy Le on 5/29/15.
//  Copyright (c) 2015 Huy Le. All rights reserved.
//

import Foundation
import UIKit

extension CGSize{
    static func screenWidth() ->CGFloat{
        return (UIScreen.mainScreen().bounds.size.width)
    }
    static func screenHeight() ->CGFloat{
        return (UIScreen.mainScreen().bounds.size.height)
    }
}