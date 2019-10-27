//
//  HTMLStringDecoder.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 9/28/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import Foundation
extension String {

    init(htmlString: String) {
        self.init()
        guard let encodedData = htmlString.data(using: .utf8) else {
            self = htmlString
            return
        }

        let attributedOptions: [NSAttributedString.DocumentReadingOptionKey : Any] = [
           .documentType: NSAttributedString.DocumentType.html,
           .characterEncoding: String.Encoding.utf8.rawValue
        ]

        do {
            let attributedString = try NSAttributedString(data: encodedData,
                                                          options: attributedOptions,
                                                          documentAttributes: nil)
            self = attributedString.string
        } catch {
            print("Error: \(error.localizedDescription)")
            self = htmlString
        }
    }
}
