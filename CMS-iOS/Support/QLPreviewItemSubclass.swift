//
//  QLPreviewItemSubclass.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 10/17/19.
//  Copyright © 2019 Crux BPHC. All rights reserved.
//

import UIKit
import QuickLook

class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?
}
