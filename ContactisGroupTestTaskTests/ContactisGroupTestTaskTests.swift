//
//  ContactisGroupTestTaskTests.swift
//  ContactisGroupTestTaskTests
//
//  Created by Siarhei Yakushevich on 7/26/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import XCTest
@testable import ContactisGroupTestTask

class ContactisGroupTestTaskTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    //MARK: - Simple operations
    
    func testCreateArithmeticExpressionsSimplePlus() {
        let analyzer = TextAnalyzer(expression: "one plus two") // 1 + 2
        let expressions = analyzer.createArithmeticExpressions()
        XCTAssertTrue(expressions.count == 3, "Not 3 operands!")
        let expectedExpressions = [ArithmeticObject.value(value: 1), ArithmeticObject.operator(operators: Operators.plus), ArithmeticObject.value(value: 2)]
        XCTAssertEqual(expressions, expectedExpressions)
    }
    
    
    func testCreateArithmeticExpressionsSimpleMinus() {
        let analyzer = TextAnalyzer(expression: "two minus four") // 2 - 4
        let expressions = analyzer.createArithmeticExpressions()
        XCTAssertTrue(expressions.count == 3, "Not 3 operands!")
        let expectedExpressions = [ArithmeticObject.value(value: 2), ArithmeticObject.operator(operators: Operators.minus), ArithmeticObject.value(value: 4)]
        XCTAssertEqual(expressions, expectedExpressions)
    }
    
    
    func testCreateArithmeticExpressionsSimpleMultiply() {
        let analyzer = TextAnalyzer(expression: "two multiply four") // 2 * 4
        let expressions = analyzer.createArithmeticExpressions()
        XCTAssertTrue(expressions.count == 3, "Not 3 operands!")
        let expectedExpressions = [ArithmeticObject.value(value: 2), ArithmeticObject.operator(operators: Operators.multiply), ArithmeticObject.value(value: 4)]
        XCTAssertEqual(expressions, expectedExpressions)
    }
    
    
    func testCreateArithmeticExpressionsSimpleMultiplyBy() {
        let analyzer = TextAnalyzer(expression: "two multiply by four") // 2 * 4
        let expressions = analyzer.createArithmeticExpressions()
        XCTAssertTrue(expressions.count == 3, "Not 3 operands!")
        let expectedExpressions = [ArithmeticObject.value(value: 2), ArithmeticObject.operator(operators: Operators.multiply), ArithmeticObject.value(value: 4)]
        XCTAssertEqual(expressions, expectedExpressions)
    }
    
    func testCreateArithmeticExpressionsSimpleDivide() {
        let analyzer = TextAnalyzer(expression: "two divide four") // 2 / 4
        let expressions = analyzer.createArithmeticExpressions()
        XCTAssertTrue(expressions.count == 3, "Not 3 operands!")
        let expectedExpressions = [ArithmeticObject.value(value: 2), ArithmeticObject.operator(operators: Operators.divide), ArithmeticObject.value(value: 4)]
        XCTAssertEqual(expressions, expectedExpressions)
    }
    
    
    func testCreateArithmeticExpressionsSimpleDivideBy() {
        let analyzer = TextAnalyzer(expression: "two divide by four") // 2 / 4
        let expressions = analyzer.createArithmeticExpressions()
        XCTAssertTrue(expressions.count == 3, "Not 3 operands!")
        let expectedExpressions = [ArithmeticObject.value(value: 2), ArithmeticObject.operator(operators: Operators.divide), ArithmeticObject.value(value: 4)]
        XCTAssertEqual(expressions, expectedExpressions)
    }
    
    //MARK: - Process Real number 
    
    func testCreateArithmeticExpressionFromRealNumber() {
        
        let analyzer = TextAnalyzer(expression: "One hundred and twenty three millions four hundred fifty six thousand seven hundred eighty nine") //123 456 789
        
        let expressions = analyzer.createArithmeticExpressions()
        XCTAssertTrue(expressions.count == 1, "Not one item!")
        XCTAssertEqual(expressions.first?.accessValue(), 123456789)
    }
    
    func testCreateSimpleSumFrom2RealNumbers() {
        let analyzer = TextAnalyzer(expression: "One hundred one million ten thousand one hundred one multiply by twenty-three plus four hundred") //101 010 101 * 23 + 400
        let expressions = analyzer.createArithmeticExpressions()
        XCTAssertTrue(expressions.count == 5, "Not 3 item!")
        let expectedExpressions = [ArithmeticObject.value(value: 101010101), ArithmeticObject.operator(operators: Operators.multiply), ArithmeticObject.value(value: 23), ArithmeticObject.operator(operators: Operators.plus),ArithmeticObject.value(value: 400)]
        XCTAssertEqual(expressions, expectedExpressions)
    }
    
    //MARK: - Remove fake signs
    
    func testCreateArithmeticExpressionsRemoveFakeFirstPlus() {
        let analyzer = TextAnalyzer(expression: "plus one plus two") // + 1 + 2
        let expressions = analyzer.createArithmeticExpressions()
        XCTAssertTrue(expressions.count == 3, "Not 3 operands!")
        let expectedExpressions = [ArithmeticObject.value(value: 1), ArithmeticObject.operator(operators: Operators.plus), ArithmeticObject.value(value: 2)]
        XCTAssertEqual(expressions, expectedExpressions)
    }
    
    func testCreateArithmeticExpressionsRemoveFakeLastPlus() {
        let analyzer = TextAnalyzer(expression: "three plus minus two") // 3 +- 2
        let expressions = analyzer.createArithmeticExpressions()
        XCTAssertTrue(expressions.count == 3, "Not 3 operands!")
        let expectedExpressions = [ArithmeticObject.value(value: 3), ArithmeticObject.operator(operators: Operators.plus), ArithmeticObject.value(value: -2)]
        XCTAssertEqual(expressions, expectedExpressions)
    }
    
    //MARK: - Check AnalyzerInner
    
    func testAnalyzeInnerSimpleCase() {
        let analyzer = TextAnalyzer(expression: "three minus one multiply by four") // 3 - 1 * 4
        let value = analyzer.analyzeInner()
        XCTAssertTrue(value == -1, "Not equal -1")
    }
    
    func testAnalyzeInnerMinusPlusGroupCase() {
        let analyzer = TextAnalyzer(expression: "ten minus five minus three minus thirty three") // 10 - 5 - 3 - 33
        let value = analyzer.analyzeInner()
        XCTAssertTrue(value == -31, "Not equal -31")
    }
    
    func testAnalyzeInnerMultDivGroupCase() {
        let analyzer = TextAnalyzer(expression: "seventy one multiply by seventy two divide by twenty four") // 71 *72/24
        let value = analyzer.analyzeInner()
        XCTAssertTrue(value == 213, "Not equal 213")
    }
    
    func testAnalyzeInnerDifferentGroupsCase() {
        let analyzer = TextAnalyzer(expression: "fifty-six minus two multiply by forty multiply by five plus six minus seven") // 56 - 2 * 40 * 5 + 6 - 7
        let value = analyzer.analyzeInner()
        XCTAssertTrue(value == -345, "Not equal -345")
    }
    
    func testAnalyzerInnerLongDifferentGroupsCase() {
        let analyzer = TextAnalyzer(expression: "One plus One minus two plus three minus three plus ten multiply by ten divide by one hundred") // 1 + 1 - 2 + 3 - 3 + 10 * 10 /100 == 1
        
        let value = analyzer.analyzeInner()
        XCTAssertTrue(value == 1, "Not equal to one!")
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
