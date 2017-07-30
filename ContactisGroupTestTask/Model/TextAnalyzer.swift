//
//  TextAnalyzer.swift
//  ContactisGroupTestTask
//
//  Created by Siarhei Yakushevich on 7/26/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation

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

//MARK: - TextAnalyzer
class TextAnalyzer {
    let text: String
    let tagger: NSLinguisticTagger
    let queue: DispatchQueue
    let options = NSLinguisticTagger.Options.omitPunctuation.union(NSLinguisticTagger.Options.omitWhitespace)
    
    let basicNumbers : [String: TextAnalyzer.NumberType] = ["one": 1,
               "two": 2,
               "three": 3,
               "four": 4,
               "five": 5,
               "six": 6,
               "seven": 7,
               "eight":8,
               "nine":9,
               "ten":10,
               "eleven": 11,
               "twelve": 12,
               "thirteen":13,
               "fifteen": 15,
               "twenty": 20,
               "thirty":30,
               "forty": 40,
               "fifty": 50,
               "sixty": 60,
               "seventy": 70,
               "eighty": 80,
               "ninety":90]
    
    let multipliersSingal : [String: TextAnalyzer.NumberType] = ["hundred"   : 100,
                             "hundreds"  : 1e+2,
                             "thousands" : 1e+3,
                             "thousand"  : 1e+3 ,
                             "million"   : 1e+6,
                             "millions"  : 1e+6,
                             "billion"   : 1e+9,
                             "billions"  : 1e+9,
                             "trillion"  : 1e+12,
                             "trillions" : 1e+12 ]
    
    typealias NumberType = Double
    typealias NumbersGroupTuple = (value1: NumberType?, value2: NumberType?, operation: Operation?)
    
    init(expression text:String) {
        self.text = text.lowercased()
        self.queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        self.tagger = NSLinguisticTagger(tagSchemes: [NSLinguisticTagSchemeLexicalClass], options: Int(options.rawValue))
    }
    
    func analyze(completion:@escaping ((_ value: TextAnalyzer.NumberType)->Void)) {
        self.queue.async { [weak self] in
            guard let sSelf = self else { return}
            
            let result = sSelf.analyzeInner()
            completion(result)
        }
    }
    
    func analyzeInner() -> TextAnalyzer.NumberType {
        let objects = createArithmeticExpressions()
        let result = process(arithmeticExpressions: objects)
        return result
    }
    
    func createArithmeticExpressions() -> [ArithmeticExpression] {
        //remove "whitespace"
        let pText = self.text.condensedWhitespace.replacingOccurrences(of: "-", with: " ") //fifty-nine
        
        //divide sence into tags...
        let components = pText.components(separatedBy: " ")
        
        let temp = components.flatMap { self.multipliersSingal[$0] }
        
        var multipliers: [TextAnalyzer.NumberType] = []
        
        var prevMutliplier = TextAnalyzer.NumberType(0)
        
        for multiplier in temp {
            if (multiplier > prevMutliplier) {
                prevMutliplier = multiplier
            }
            else {
                multipliers.append(prevMutliplier)
                prevMutliplier = multiplier
            }
        }
        
        if (prevMutliplier != 0) {
            multipliers.append(prevMutliplier)
        }
        
        var multiplierIndex = multipliers.startIndex
        
        var detectingNumber = false
        var value: NumberType? = nil
        var minusDetectedCount = 0
        var isPositive = true
        var prevOperation: ArithmeticExpression? = nil
        var prevPartValue: NumberType? = nil
        
        var objects = [ArithmeticExpression]()
        
        for i in components.startIndex..<components.endIndex {
            let component = components[i]
            if let fDigit = self.basicNumbers[component] {
                if (!detectingNumber) {
                    detectingNumber = true
                    prevPartValue = fDigit
                    value = nil
                    
                    if let op = prevOperation, !objects.isEmpty {
                        objects.append(op)
                        prevOperation = nil
                    }
                }
                else {
                    if var prev = prevPartValue {
                        prev += fDigit
                        prevPartValue = prev
                    }
                    else {
                        prevPartValue = fDigit
                    }
                }
            }
            else if let multiplier = self.multipliersSingal[component] {
                
                
                
                if var prev = prevPartValue {
                    prev *= multiplier
                    prevPartValue = prev
                }
                else {
                    prevPartValue = 1 //1 million instead of million
                }
                
                
                let needResetPrev = multipliers.endIndex != multiplierIndex ? multipliers[multiplierIndex] == multiplier : true
                
                /*if (i != components.count - 1 ) {
                    let next = components[i+1]
                    if (next == "and" /*|| self.basicNumbers[next] != nil*/) {
                        needResetPrev = false
                    }
                }*/
                
                if needResetPrev {
                    if multipliers.endIndex != multiplierIndex {
                        multiplierIndex = multipliers.index(after: multiplierIndex)
                    }
                    
                    if var val = value {
                        val += prevPartValue!
                        value = val
                    }
                    else {
                        value = prevPartValue!
                    }
                    prevPartValue = nil
                }
            }
            else if let operation = Operation(rawValue: component){
                prevOperation = ArithmeticExpression.operation(operation: operation)
                
                if (detectingNumber) {
                    
                    if let prev = prevPartValue {
                        if (value == nil) {
                            value = prev
                        }
                        else {
                            value! += prev
                        }
                    }
                    
                    if (value == nil) {
                        value = NumberType(0)
                    }
                    
                    if (!isPositive) {
                        value! *= -1
                        isPositive = true
                    }
                    
                    let tempValue = ArithmeticExpression.value(value: value!)
                    objects.append(tempValue)
                    detectingNumber = false
                }
                else if operation == .minus {
                    if (minusDetectedCount == 0) {
                        minusDetectedCount += 1
                        isPositive = false
                        prevOperation = ArithmeticExpression.operation(operation: Operation.plus)
                    }
                    else {
                        isPositive = true
                        debugPrint("WARNING double minus detected!")
                        prevOperation = ArithmeticExpression.operation(operation: Operation.plus)
                    }
                }
                else  {
                    minusDetectedCount = 0
                    
                    if operation == .plus {
                        if (!isPositive) {
                            //Store minus....
                            prevOperation = ArithmeticExpression.operation(operation: Operation.minus)
                            isPositive = true
                        }
                    }
                    
                }
                
                //objects.append(tempObject)
            }
            else if component == "by" ||
                    component == "and" { // multiply by , divide by, one million and
                continue
            }
            else {
                debugPrint("WARNING unsupported operation detected! \(component)")
            }
        }
        
        if (detectingNumber) {
            
            if let prev = prevPartValue {
                if (value == nil) {
                    value = prev
                }
                else {
                    value! += prev
                }
            }
            
            if (value == nil) {
                value = NumberType(0)
            }
            
            if (!isPositive) {
                value! *= -1
                isPositive = true
            }
            
            let tempValue = ArithmeticExpression.value(value: value!)
            objects.append(tempValue)
            detectingNumber = false
        }
        else if let op = prevOperation {
            objects.append(op)
            prevOperation = nil
        }
        
        return objects
    }
    
    func process(arithmeticExpressions objects: [ArithmeticExpression]) -> TextAnalyzer.NumberType {
        let opIndexes = detect(inObjects: objects)
        
        var newObjects: [ArithmeticExpression] = []
        
        var result = TextAnalyzer.NumberType(0)
        
        if let fIndexes = opIndexes.first {
            let fRangeValues = simplify(inObjects: objects, operationIndexes: fIndexes)
            
            var prevRange = objects.startIndex
            
            for rangeValue in fRangeValues {
            
                // Copy items before range & after range...
                
                let subRange = objects[prevRange..<rangeValue.range.lowerBound]
                newObjects.append(contentsOf: subRange)
                newObjects.append(ArithmeticExpression.value(value: rangeValue.value))
                prevRange = objects.index(after: rangeValue.range.upperBound).advanced(by: 1)
            }
            
            let subRange = objects[prevRange..<objects.endIndex]
            newObjects.append(contentsOf: subRange)
        }
        
        if let opIndexes2 = detect(inObjects: newObjects).first {
            let fRangeValues = simplify(inObjects: newObjects, operationIndexes: opIndexes2)
            
            assert(fRangeValues.count == 1 )
            result = fRangeValues.first!.value
        }
        else {
            result = newObjects.first!.accessValue()!
        }
        
        return result
        
    }
    
    func detect(inObjects objects:[ArithmeticExpression]) -> [[Array<Operation>.Index]] { //multiply, divide -> plus, minus...
        
        var index = objects.startIndex
        
        var firstLevel: [Array<Operation>.Index] = []
        var secondLevel: [Array<Operation>.Index] = []
        
        while (index != objects.endIndex) {
            
            let element = objects[index]
            
            if let op = element.accessOperation() {
                switch op {
                case .multiply: fallthrough
                case .divide:
                    firstLevel.append(index)
                    break
                case .plus: fallthrough
                case .minus:
                    secondLevel.append(index)
                    break
                }
            }
            
            index = objects.index(after: index)
        }
        
        var result: [[Array<Operation>.Index]] = []
        
        if (!firstLevel.isEmpty) {
            result.append(firstLevel)
        }
        
        if (!secondLevel.isEmpty) {
            result.append(secondLevel)
        }
        
        return result
    }
    
    func simplify(inObjects objects:[ArithmeticExpression], operationIndexes indexes:[Array<Operation>.Index]) -> [(range: Range<Array<Operation>.Index>, value: TextAnalyzer.NumberType) ] {
        
        let startIndex = indexes.startIndex
        let endIndex = indexes.endIndex
        
        var prevValue: TextAnalyzer.NumberType! = nil
        
        var index = startIndex
        var innerIndex = objects.startIndex
        var prevIndex = innerIndex
        
        var groupIndex: Array<Operation>.Index! = nil
        
        var result: [(range:Range<Array<Operation>.Index>, value: TextAnalyzer.NumberType)] = []
        
        while (index != endIndex) {
            
            var defValue: TextAnalyzer.NumberType! = nil
            
            innerIndex = indexes[index]
            
            if let op = objects[innerIndex].accessOperation() {
                
                switch op {
                case .multiply: fallthrough
                case .divide:
                    defValue = TextAnalyzer.NumberType(1)
                    break
                case .minus: fallthrough
                case .plus:
                    defValue = TextAnalyzer.NumberType(0)
                    break
                }
            }
            
            var lValue: TextAnalyzer.NumberType! = nil
                
            if (innerIndex - prevIndex == 2) {
                lValue = prevValue
                
            }
            else  {
                
                if (groupIndex != nil) {
                    result.append((range: groupIndex..<innerIndex, value: prevValue))
                    
                    groupIndex = nil
                }
                
                lValue = defValue
                
                if (innerIndex != objects.startIndex) {
                    let tIndex = objects.index(before: innerIndex)
                    
                    if (groupIndex == nil) {
                        groupIndex = tIndex
                    }
                    
                    if let value = objects[tIndex].accessValue() {
                        lValue = value
                    }
                    else {
                        debugPrint("Warning!")
                    }
                }
            }
            
            
            
            var rValue = defValue
            if (innerIndex != objects.endIndex) {
                let tIndex = objects.index(after: innerIndex)
                if let value = objects[tIndex].accessValue() {
                    rValue = value
                }
                else {
                    debugPrint("Warning!")
                }
            }
            
            var result = TextAnalyzer.NumberType(0)
            
            if let op = objects[innerIndex].accessOperation(), let r = rValue, let l = lValue {
                
                switch op {
                case .multiply:
                    result = l * r
                    break
                case .divide:
                    result = l / r
                    break
                case .minus:
                    result = l - r
                    break
                case .plus:
                    result = l + r
                    break
                }
            }
            
            prevValue = result
            prevIndex = innerIndex
            
            index = indexes.index(after: index)
        }
        
        if (groupIndex != nil) {
            result.append((range: groupIndex..<innerIndex, value: prevValue))
            
            groupIndex = nil
        }
        
        return result
    }
}
