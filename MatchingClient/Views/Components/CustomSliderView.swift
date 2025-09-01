//
//  CustomSliderView.swift
//  Chat
//
//  Created by 宮田涼 on 2024/03/10.
//

import SwiftUI

struct CustomSliderView: View {

    var initValue: Int?
    @Binding var value: Int
    
    @State private var width: CGFloat = 0
    @State private var totalScreen: CGFloat = 0
    @State private var isDraggingLeft = false
    @State private var isDraggingRight = false

    private let minValue: CGFloat = 10
    private let maxValue: CGFloat = 301
    private let offsetValue: CGFloat = 55
    
    private let sliderHeight: CGFloat = 10
    private let dotWidth: CGFloat = 40
    private let frameHeight: CGFloat = 100
    
    private var seekValue: Int {
        let val = Int(SliderViewUtils.map(value: width, from: 0...totalScreen, to: minValue...maxValue))
        value = val
        return val
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Text("自分からの距離")
                            .foregroundStyle(Theme.Text.primary)
                            .font(.system(.subheadline, design: .monospaced))
                        Spacer()

                        let valueLabel = (seekValue > (Int(maxValue) - 1)) ? "制限なし" : "\(seekValue)km"
                        
                        Text(valueLabel)
                            .foregroundStyle(Theme.Text.primary)
                            .font(.system(.subheadline, design: .monospaced))
                            .bold()
                    }
                    .padding(.bottom, 10)

                    ZStack(alignment: .leading) {
                    
                        ZStack(alignment: .leading) {
                            // シークバー
                            Rectangle()
                                .foregroundStyle(Color.gray.opacity(0.2))
                                .frame(height: sliderHeight)

                            // シークバーのメーター
                            Rectangle()
                                .fill(Theme.buttonGradient)
                                .frame(width: width, height: sliderHeight)
                        }
                        .cornerRadius(.infinity)

                        HStack(spacing: 0) {
                            DraggbleCircle(
                                isDragging: $isDraggingLeft,
                                position: $width,
                                limit: totalScreen,
                                dotSize: dotWidth
                            )
                        }
                    }
                }
                .frame(width: geometry.size.width, height: frameHeight)
                .onAppear() {
                    totalScreen = geometry.size.width - dotWidth
                    // バーを最大から始める
                    if let initValue {
                        width = SliderViewUtils.reverseMap(mappedValue: CGFloat(initValue), from: 0...totalScreen, to: minValue...maxValue)
                    } else {
                        width = totalScreen
                    }
                }
            }
            .frame(height: frameHeight)
        }
    }
}

private struct DraggbleCircle: View {

    @Binding var isDragging: Bool
    @Binding var position: CGFloat
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
                    position = min(max(value.location.x, 0), limit)
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
    CustomSliderView(value: .constant(0))
}