//
//  File.swift
//  ContactisGroupTestTask
//
//  Created by Siarhei Yakushevich on 8/1/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation

final class NativeSpeechAdapter {
    
    class func convertToWords(mixedText text: String) -> String {
        var result = ""
        var prevValue  = 0
        
        for ch in text.characters {
            let chStr = String(ch)
            if "0"..."9" ~= ch || (chStr == "," && prevValue != 0) {
                if let someInt = Int(chStr) {
                    prevValue = prevValue * 10 + someInt
                }
            }
            else {
                
                if (prevValue != 0) {
                    if let lastCh = result.last, String(lastCh) != " " {
                        result.append(" ")
                    }
                    result.append(TextAnalyzer.convertToString(TextAnalyzer.NumberType(prevValue)))
                    result.append(" ")
                    prevValue = 0
                }
                
                var temp: String! //TODO: place inside Operation
                switch chStr {
                case "+":
                    temp = "plus"
                    break
                case "-":
                    temp = "minus"
                    break
                case "×": fallthrough
                case "*":
                    temp = "multiply by"
                    break
                case "/":
                    temp = "divide by"
                    break
                default:
                    temp = nil
                    break
                }
                
                if (temp != nil) {
                    if let lastCh = result.last, String(lastCh) != " " {
                        result.append(" ")
                    }
                    result.append(temp)
                    result.append(" ")
                }
                else { //ignore commas...
                    result.append(chStr)
                }
                
            }
        }
        
        if (prevValue != 0) {
            if let lastCh = result.last, String(lastCh) != " " {
                result.append(" ")
            }
            result.append(TextAnalyzer.convertToString(TextAnalyzer.NumberType(prevValue)))
            result.append(" ")
            prevValue = 0
        }
        
        return result.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
}
