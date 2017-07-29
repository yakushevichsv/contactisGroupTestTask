//
//  StringExtensions.swift
//  ContactisGroupTestTask
//
//  Created by Siarhei Yakushevich on 7/27/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation

extension String {
    var condensedWhitespace: String {
        let components = self.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
}
