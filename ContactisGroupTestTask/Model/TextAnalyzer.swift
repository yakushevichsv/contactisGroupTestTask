//
//  TextAnalyzer.swift
//  ContactisGroupTestTask
//
//  Created by Siarhei Yakushevich on 7/26/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation

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
        case "multiply":
            self = .multiply
            break
        case "divide":
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
    
    let basicNumbers = ["one": 1,
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
    
    let multipliersSingal = ["hundred"   : 100,
                             "hundreds"  : 100,
                             "thousands" : 1000,
                             "thousand"  : 1000 ,
                             "million"   : 1000000,
                             "millions"  : 1000000,
                             "billion"   : 1000000000,
                             "billions"  : 1000000000]
    
    typealias NumberType = Int
    typealias NumbersGroupTuple = (value1: NumberType?, value2: NumberType?, operation: Operators?)
    
    init(expression text:String) {
        self.text = text
        self.queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        self.tagger = NSLinguisticTagger(tagSchemes: [NSLinguisticTagSchemeLexicalClass], options: Int(options.rawValue))
    }
    
    func analyze(completion:@escaping (()->Void)) {
        self.queue.async { [weak self] in
            guard let sSelf = self else { return}
            
            
            
            /*let textStr = NSString(string: sSelf.text)
            let range = NSRange(location: 0, length: textStr.length)
            sSelf.tagger.enumerateTags(in: range, scheme: sSelf.tagger.tagSchemes.first!, options: sSelf.options, using: { (tag, tagRange, sentenceRange, ptr) in
                
                debugPrint("Tag \(tag) tagRange \(NSStringFromRange(tagRange)) sentenceRange \(NSStringFromRange(sentenceRange)) \n")
            })
            
            completion() */
            
            //remove "whitespace"
            let pText = sSelf.text.condensedWhitespace.replacingOccurrences(of: "-", with: " ") //fifty-nine
            
            //divide sence into tags...
            let components = pText.components(separatedBy: " ")
            
            
            var detectingNumber = false
            var value: NumberType = NumberType(0)
            var minusDetectedCount = 0
            var isPositive = true
            
            var tuples = [NumbersGroupTuple]()
            
            var cTuple: NumbersGroupTuple = (value1: nil , value2: nil, operation: nil)
            
            for component in components {
                if let fDigit = sSelf.basicNumbers[component] {
                    if (!detectingNumber) {
                        detectingNumber = true
                        value = fDigit
                        
                        if (isPositive == false) {
                            value *= -1
                            isPositive = true
                        }
                    }
                    else {
                        value += fDigit
                    }
                }
                else if let multiplier = sSelf.multipliersSingal[component] {
                    value *= multiplier
                }
                else if let operation = Operators(rawValue: component){
                    if (detectingNumber) {
                        detectingNumber = false  // Detected number one...
                        
                        if (sSelf.filled(tuple: &cTuple, value: value)) {
                            tuples.append(cTuple)
                            
                            cTuple = (value1: nil , value2: nil, operation: nil)
                            detectingNumber = false
                            value = NumberType(0)
                            minusDetectedCount = 0
                            isPositive = true
                        }
                    }
                    else if operation == .minus {
                        if (minusDetectedCount == 0) {
                            minusDetectedCount += 1
                            isPositive = false
                        }
                        else {
                            isPositive = true
                            debugPrint("WARNING double minus detected!")
                        }
                    }
                    else if operation == .plus {
                        isPositive = true
                    }
                    else {
                        debugPrint("WARNING * or / detected!")
                    }
                }
                else {
                    continue
                }
            }
            
            //TODO: Process unfinished tuple....
            
        }
    }
    
    func filled( tuple: inout NumbersGroupTuple, value: NumberType) -> Bool {
        if tuple.value1 != nil {
            tuple.value2 = value
            assert(tuple.operation != nil)
            return true
        }
        else {
            tuple.value1 = value
            return false
        }
    }
}
