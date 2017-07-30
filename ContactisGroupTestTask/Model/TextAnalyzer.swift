//
//  TextAnalyzer.swift
//  ContactisGroupTestTask
//
//  Created by Siarhei Yakushevich on 7/26/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation

enum ArithmeticObject: Equatable {
    case unknown
    case `operator`(operators:Operators)
    case value(value: TextAnalyzer.NumberType)
    
    public static func == (lhs: ArithmeticObject, rhs: ArithmeticObject) -> Bool {
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
    
    func accessOperation() -> Operators? {
        switch self {
        case .operator(let op):
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

enum Operators: String, RawRepresentable {
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
    typealias NumbersGroupTuple = (value1: NumberType?, value2: NumberType?, operation: Operators?)
    
    init(expression text:String) {
        self.text = text.lowercased()
        self.queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        self.tagger = NSLinguisticTagger(tagSchemes: [NSLinguisticTagSchemeLexicalClass], options: Int(options.rawValue))
    }
    
    func analyze(completion:@escaping ((_ value: TextAnalyzer.NumberType)->Void)) {
        self.queue.async { [weak self] in
            guard let sSelf = self else { return}
            
            let objects = sSelf.createArithmeticExpressions()
            let result = sSelf.process(arithmeticObjects: objects)
            completion(result)
        }
    }
    
    func createArithmeticExpressions() -> [ArithmeticObject] {
        
        /*let textStr = NSString(string: sSelf.text)
         let range = NSRange(location: 0, length: textStr.length)
         sSelf.tagger.enumerateTags(in: range, scheme: sSelf.tagger.tagSchemes.first!, options: sSelf.options, using: { (tag, tagRange, sentenceRange, ptr) in
         
         debugPrint("Tag \(tag) tagRange \(NSStringFromRange(tagRange)) sentenceRange \(NSStringFromRange(sentenceRange)) \n")
         })
         
         completion() */
        
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
        var prevOperation: ArithmeticObject? = nil
        var prevPartValue: NumberType? = nil
        
        var objects = [ArithmeticObject]()
        
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
            else if let operation = Operators(rawValue: component){
                prevOperation = ArithmeticObject.operator(operators: operation)
                
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
                    
                    let tempValue = ArithmeticObject.value(value: value!)
                    objects.append(tempValue)
                    detectingNumber = false
                }
                else if operation == .minus {
                    if (minusDetectedCount == 0) {
                        minusDetectedCount += 1
                        isPositive = false
                        prevOperation = ArithmeticObject.operator(operators: Operators.plus)
                    }
                    else {
                        isPositive = true
                        debugPrint("WARNING double minus detected!")
                        prevOperation = ArithmeticObject.operator(operators: Operators.plus)
                    }
                }
                else  {
                    minusDetectedCount = 0
                    
                    if operation == .plus {
                        if (!isPositive) {
                            //Store minus....
                            prevOperation = ArithmeticObject.operator(operators: Operators.minus)
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
            
            let tempValue = ArithmeticObject.value(value: value!)
            objects.append(tempValue)
            detectingNumber = false
        }
        else if let op = prevOperation {
            objects.append(op)
            prevOperation = nil
        }
        
        return objects
    }
    
    func process(arithmeticObjects objects: [ArithmeticObject]) -> TextAnalyzer.NumberType {
        let opIndexes = detect(inObjects: objects)
        
        var newObjects: [ArithmeticObject] = []
        
        var result = TextAnalyzer.NumberType(0)
        
        if let fIndexes = opIndexes.first {
            let fRangeValues = simplify(inObjects: objects, operationIndexes: fIndexes)
            
            var prevRange = objects.startIndex
            
            for rangeValue in fRangeValues {
            
                // Copy items before range & after range...
                
                let subRange = objects[prevRange..<rangeValue.range.lowerBound]
                newObjects.append(contentsOf: subRange)
                
                prevRange = objects.index(after: rangeValue.range.upperBound)
            }
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
    
    func detect(inObjects objects:[ArithmeticObject]) -> [[Array<Operators>.Index]] { //multiply, divide -> plus, minus...
        
        var index = objects.startIndex
        
        var firstLevel: [Array<Operators>.Index] = []
        var secondLevel: [Array<Operators>.Index] = []
        
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
        
        var result: [[Array<Operators>.Index]] = []
        
        if (!firstLevel.isEmpty) {
            result.append(firstLevel)
        }
        
        if (!secondLevel.isEmpty) {
            result.append(secondLevel)
        }
        
        return result
    }
    
    func simplify(inObjects objects:[ArithmeticObject], operationIndexes indexes:[Array<Operators>.Index]) -> [(range: Range<Array<Operators>.Index>, value: TextAnalyzer.NumberType) ] {
        
        let startIndex = indexes.startIndex
        let endIndex = indexes.endIndex
        
        var prevValue: TextAnalyzer.NumberType! = nil
        var prevIndex = startIndex
        
        var index = startIndex
        
        var groupIndex: Array<Operators>.Index! = nil
        
        var result: [(range:Range<Array<Operators>.Index>, value: TextAnalyzer.NumberType)] = []
        
        while (index != endIndex) {
            
            var defValue: TextAnalyzer.NumberType! = nil
            
            if let op = objects[index].accessOperation() {
                
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
                
            if (index - prevIndex == 2) {
                lValue = prevValue
                
            }
            else  {
                
                if (groupIndex != nil) {
                    result.append((range: groupIndex..<index, value: prevValue))
                    
                    groupIndex = nil
                }
                
                lValue = defValue
            }
            
            if (index != startIndex) {
                let tIndex = objects.index(before: index)
                
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
            
            var rValue = defValue
            if (index != endIndex) {
                let tIndex = objects.index(after: index)
                if let value = objects[tIndex].accessValue() {
                    rValue = value
                }
                else {
                    debugPrint("Warning!")
                }
            }
            
            var result = TextAnalyzer.NumberType(0)
            
            if let op = objects[index].accessOperation(), let r = rValue, let l = lValue {
                
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
            prevIndex = index
            
            index = objects.index(after: index)
        }
        
        if (groupIndex != nil) {
            result.append((range: groupIndex..<index, value: prevValue))
            
            groupIndex = nil
        }
        
        return result
    }
}