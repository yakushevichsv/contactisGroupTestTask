//
//  ArithmeticExpression.swift
//  ContactisGroupTestTask
//
//  Created by Siarhei Yakushevich on 7/30/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation

//MARK: - ArithmeticExpression
enum ArithmeticExpression: Equatable {
    case unknown
    case operation(operation: Operation)
    case value(value: TextAnalyzer.NumberType)
    
    public static func == (lhs: ArithmeticExpression, rhs: ArithmeticExpression) -> Bool {
        let op1 = lhs.accessOperation()
        let op2 = rhs.accessOperation()
        
        if let o1 = op1, let o2 = op2 {
            return o1 == o2
        }
        
        let v1Ptr = lhs.accessValue()
        let v2Ptr = rhs.accessValue()
        
        if let v1 = v1Ptr, let v2 = v2Ptr {
            return v1 == v2
        }
        return false
    }
    
    func accessOperation() -> Operation? {
        switch self {
        case .operation(let op):
            return op
        default:
            return nil
        }
    }
    
    func accessValue() -> TextAnalyzer.NumberType? {
        switch self {
        case .value(let value):
            return value
        default:
            return nil
        }
    }
}
