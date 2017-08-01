//
//  TextAnalyzer.swift
//  ContactisGroupTestTask
//
//  Created by Siarhei Yakushevich on 7/26/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation

//MARK: - TextAnalyzer
class TextAnalyzer {
    private var _text = ""
    
    var text: String {
        set {
            _text = newValue.lowercased()
        }
        get {
            return _text
        }
    }
    
    let queue: DispatchQueue
    
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
               "fourteen":14,
               "fifteen": 15,
               "sixteen":16,
               "seventeen": 17,
               "eighteen":18,
               "nineteen": 19,
               "twenty": 20,
               "thirty":30,
               "forty": 40,
               "fifty": 50,
               "sixty": 60,
               "seventy": 70,
               "eighty": 80,
               "ninety":90]
    

    lazy var basicNumbersOpposite: [TextAnalyzer.NumberType: String] = {
        
        var result: [TextAnalyzer.NumberType: String] = [:]
        
        for basicPair in self.basicNumbers {
            result[basicPair.value] = basicPair.key
        }
        
        return result
    }()
    
    let multipliersSingal : [String: TextAnalyzer.NumberType] =
                            ["hundred"   : 1e+2,
                             "hundreds"  : 1e+2,
                             "thousands" : 1e+3,
                             "thousand"  : 1e+3 ,
                             "million"   : 1e+6,
                             "millions"  : 1e+6,
                             "billion"   : 1e+9,
                             "billions"  : 1e+9,
                             "trillion"  : 1e+12,
                             "trillions" : 1e+12 ]
    
    
    lazy var multipliersSignalOpposite: [TextAnalyzer.NumberType : String] = {
       
        var result: [TextAnalyzer.NumberType: String] = [:]
        
        for basicPair in self.multipliersSingal {
            if (result[basicPair.value] == nil && basicPair.key.characters.last != "s") {
                result[basicPair.value] = basicPair.key
            }
        }
        return result
    }()
    
    typealias NumberType = Double
    
    convenience init() {
        self.init(expression: "")
    }
    
    init(expression text:String) {
        self.queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        self.text = text
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
    
    
    class func convertToString(_ value : TextAnalyzer.NumberType) -> String {
        //TODO: refactor this.
        return TextAnalyzer().convertToString(value)
    }
    
    /*
     Convert value to string representation
     345 -> three hundred forty five....
     * Can be done using 
     * NSNumberFormatter *numberFormatter = [[NSNumberFormatter new];
     * [numberFormatter setNumberStyle:NSNumberFormatterSpellOutStyle];
    */
    func convertToString(_ value : TextAnalyzer.NumberType) -> String {
       var intValue = Int(value)
        
        assert(value == Double(intValue)) // support just only integer items...
        
        var digits = [Int]()
        
        var tempInt = intValue
        while (tempInt != 0 ){
            let newIntValue = tempInt/10
            let reminder = tempInt - newIntValue * 10
            digits.append(reminder)
            tempInt = newIntValue
        }
        
        digits.reverse()
        
        
        let maxPower = digits.count - 1

        let supportedPowers = [12, 9 , 6, 3, 2, 0]
        
        var index = supportedPowers.startIndex
        //Can be thousand of trillions...
        var providedPower =  maxPower
        
        var result = ""
        var partStr = ""
        
        while (index != supportedPowers.endIndex && providedPower >= 0) {
            let currentPower = supportedPowers[index]
            
            if (currentPower <=  providedPower) {
                let divider = Int(pow(Double(10),Double(currentPower)))
                let valuePart = intValue/divider
                
                partStr = ""
                
                if valuePart < 100 {
                    if let fValueStr = self.basicNumbersOpposite[TextAnalyzer.NumberType(valuePart)] {
                        partStr = fValueStr
                    }
                    else if (valuePart > 20) {
                        let wholePart = valuePart/10
                        let valueWithoutReminder = wholePart * 10
                        let reminder = valuePart - valueWithoutReminder
                        
                        let decimalsStr = self.basicNumbersOpposite[TextAnalyzer.NumberType(valueWithoutReminder)]!
                        let digitsStr = self.basicNumbersOpposite[TextAnalyzer.NumberType(reminder)]!
                        
                        partStr = "\(decimalsStr)-\(digitsStr)"
                    }
                    
                    if (valuePart >= 10 ) {
                        providedPower -= 2
                    }
                    else {
                        providedPower -= 1
                    }
                }
                else {
                    partStr = convertToString(TextAnalyzer.NumberType(valuePart))
                    
                }
                
                if valuePart != 0, let str = self.multipliersSignalOpposite[TextAnalyzer.NumberType(divider)] {
                    
                    partStr.append(" ")
                    partStr.append(str)
                    /*if (valuePart != 1) {
                        partStr.append("s")
                    }*/
                    
                    if (!result.isEmpty) {
                        result.append(" ")
                    }
                    result.append(partStr)
                    partStr = ""
                }
                
                
                intValue -= valuePart * divider
            }
            
            index = supportedPowers.index(after: index)
        }
        
        if (!partStr.isEmpty) {
            if (!result.isEmpty) {
                result.append(" ")
            }
            result.append(partStr)
        }
        
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
            let fRangeValues = simplify(inObjects: objects, operationIndexes: fIndexes) //TODO: should have a flag... No need to process all operations, just multiplication. 
            //During second call addition, and substraction.
            
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
            
            //assert(fRangeValues.count == 1 )
            result = fRangeValues.first?.value ?? TextAnalyzer.NumberType(0)
        }
        else {
            result = newObjects.first?.accessValue() ?? TextAnalyzer.NumberType(0)
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
                if tIndex != objects.endIndex , let value = objects[tIndex].accessValue() {
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
