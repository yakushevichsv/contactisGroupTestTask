//
//  Operation.swift
//  ContactisGroupTestTask
//
//  Created by Siarhei Yakushevich on 7/30/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation

//MARK: - Operation
enum Operation: String, RawRepresentable {
    typealias RawValue = String
    
    case plus
    case minus
    case multiply
    case divide
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "plus":
            self = .plus
            break
        case "minus":
            self = .minus
            break
        case "multiply": fallthrough
        case "multiply by":
            self = .multiply
            break
        case "divide": fallthrough
        case "divide by":
            self = .divide
            break
        default:
            return nil
        }
    }
    
    var rawValue: RawValue {
        switch self {
        case .plus:
            return "plus"
        case .minus:
            return "minus"
        case .multiply:
            return "multiply"
        case .divide:
            return "divide"
        }
    }
}
