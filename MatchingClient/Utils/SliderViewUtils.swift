//
//  SliderViewUtils.swift
//  Chat
//
//  Created by 宮田涼 on 2024/08/18.
//

import Foundation

class SliderViewUtils {
    
    /// シークの値を項目の値に変換
    static func map(value: CGFloat, from: ClosedRange<CGFloat>, to: ClosedRange<CGFloat>) -> CGFloat {
        let inputRange = from.upperBound - from.lowerBound
        guard inputRange != 0 else { return 0 }
        let outputRange = to.upperBound - to.lowerBound
        return (value - from.lowerBound) / inputRange * outputRange + to.lowerBound
    }

    /// 項目の値をシークの値に変換
    static func reverseMap(mappedValue: CGFloat, from: ClosedRange<CGFloat>, to: ClosedRange<CGFloat>) -> CGFloat {
        let outputRange = to.upperBound - to.lowerBound
        guard outputRange != 0 else { return 0 }
        let inputRange = from.upperBound - from.lowerBound
//        print("(mappedValue: \(mappedValue) - to.lowerBound: \(to.lowerBound)) / outputRange: \(outputRange) * inputRange: \(inputRange) + from.lowerBound: \(from.lowerBound) = \((mappedValue - to.lowerBound) / outputRange * inputRange + from.lowerBound)")
        return (mappedValue - to.lowerBound) / outputRange * inputRange + from.lowerBound
    }
    
}