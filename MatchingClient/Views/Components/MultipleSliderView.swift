//
//  MultipleSliderView.swift
//  Chat
//
//  Created by 宮田涼 on 2024/03/06.
//

import SwiftUI

struct MultipleSliderView: View {

    var initLowerValue: Int?
    var initUpperValue: Int?
    
    @Binding var lowerValue: Int
    @Binding var upperValue: Int
    
    private var lowerVal: Int {
        let value = Int(SliderViewUtils.map(value: width, from: 0...totalScreen, to: minValue...maxValue))
        lowerValue = value
        return value
    }
    
    private var upperVal: Int {
        let value = Int(SliderViewUtils.map(value: widthTow, from: 0...totalScreen, to: minValue...maxValue))
        upperValue = value
        return value
    }
    
    @State private var width: CGFloat = 0
    @State private var widthTow: CGFloat = 0
    @State private var totalScreen: CGFloat = 0
    @State private var isDraggingLeft = false
    @State private var isDraggingRight = false

    private let minValue: CGFloat = 18
    private let maxValue: CGFloat = 61
    private let offsetValue: CGFloat = 55
    
    private let sliderHeight: CGFloat = 10
    private let dotWidth: CGFloat = 40
    private let frameHeight: CGFloat = 100
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Text("年齢")
                            .foregroundStyle(Theme.Text.primary)
                            .font(.system(.subheadline, design: .monospaced))
                        Spacer()

                        let minLabel = (lowerVal > Int(maxValue) - 1) ? Int(maxValue) - 1 : lowerVal
                        let maxLabel = (upperVal == Int(maxValue)) ? "制限なし" : "\(upperVal)"
                        
                        Text("\(minLabel)~\(maxLabel)")
                            .foregroundStyle(Theme.Text.primary)
                            .font(.system(.subheadline, design: .monospaced))
                            .bold()
                    }
                    .padding(.bottom, 10)

                    ZStack(alignment: .leading) {
                        // シークバー
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(Color.gray.opacity(0.2))
                            .frame(height: sliderHeight)
                        // シークバーのメーター
                        Rectangle()
                            .fill(Theme.buttonGradient)
                            .frame(width: widthTow - width, height: sliderHeight)
                            // ツマみの分を右にずらす
                            .offset(x: width + dotWidth)
                        HStack(spacing: 0) {
                            DraggbleCircle(
                                isLeft: true,
                                isDragging: $isDraggingLeft,
                                position: $width,
                                otherPosition: $widthTow,
                                limit: totalScreen,
                                dotSize: dotWidth
                            )
                            DraggbleCircle(
                                isLeft: false,
                                isDragging: $isDraggingRight,
                                position: $widthTow,
                                otherPosition: $width,
                                limit: totalScreen,
                                dotSize: dotWidth
                            )
                        }
                    }
                }
                .frame(width: geometry.size.width, height: frameHeight)
                .onAppear() {
                    totalScreen = geometry.size.width - dotWidth * 2
                    
                    if let value = initLowerValue {
                        width = SliderViewUtils.reverseMap(mappedValue: CGFloat(value), from: 0...totalScreen, to: minValue...maxValue)
                    }

                    if let value = initUpperValue {
                        widthTow = SliderViewUtils.reverseMap(mappedValue: CGFloat(value), from: 0...totalScreen, to: minValue...maxValue)
                    } else {
                        // バーを最大から始める
                        widthTow = totalScreen
                    }
                }
            }
            .frame(height: frameHeight)
        }
    }
}

private struct DraggbleCircle: View {

    var isLeft: Bool
    @Binding var isDragging: Bool
    @Binding var position: CGFloat
    @Binding var otherPosition: CGFloat
    var limit: CGFloat
    var dotSize: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: dotSize, height: dotSize)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                .overlay(
                    Circle()
                        .stroke(Theme.primaryColor, lineWidth: 3)
                )
        }
        .offset(x: position)
        .gesture(
            DragGesture()
                .onChanged({ value in
                    withAnimation {
                        isDragging = true
                    }
                    if isLeft {
                        position = min(max(value.location.x, 0), otherPosition)
                    } else {
                        position = min(max(value.location.x, otherPosition), limit)
                    }
                })
                .onEnded({ value in
                    withAnimation {
                        isDragging = false
                    }
                })
        )
    }
}

#Preview {
    MultipleSliderView(lowerValue: .constant(18), upperValue: .constant(61))
        .previewLayout(.sizeThatFits)
}