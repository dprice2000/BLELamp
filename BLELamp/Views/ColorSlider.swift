//
//  ColorSlider.swift
//  BLELamp
//
//  Created by David Price on 4/26/25.
//

import SwiftUI

/**
 * Public functions:
 * - body
 */
struct ColorSlider: View {
    let p_label: String
    @Binding var p_value: Double
    let p_saturationValue: Double
    let p_brightnessValue: Double

    /**
     * Main view body.
     */
    var body: some View {
        VStack {
            Text(p_label)
                .font(.system(size: 16))
                .frame(maxWidth: .infinity, alignment: .center)
            HStack {
                ZStack {
                    // The actual slider
                    Slider(
                        value: $p_value,
                        in: 0...255,
                        step: 1
                    )
                    .tint(hueColor)
                    // The colored thumb overlay (now in foreground)
                    GeometryReader { geometry in
                        let sliderHeight = geometry.size.height
                        let thumbSize = sliderHeight
                        let sliderWidth = geometry.size.width
                        let minX = thumbSize / 2
                        let maxX = sliderWidth - thumbSize / 2
                        let percent = CGFloat(p_value / 255)
                        let thumbPosition = minX + percent * (maxX - minX)
                        Circle()
                            .fill(thumbColor)
                            .frame(width: thumbSize, height: thumbSize)
                            .position(x: thumbPosition, y: sliderHeight / 2)
                            .shadow(radius: 2)
                    }
                    .allowsHitTesting(false)
                }
                .frame(height: 28)
            }
        }
    }

    /// The color based on the current value, mapped to hue (HSV)
    private var hueColor: Color {
        Color(hue: p_value / 255, saturation: 1, brightness: 1)
    }
    
    /// The color for the thumb, incorporating saturation and value
    private var thumbColor: Color {
        Color(hue: p_value / 255, saturation: p_saturationValue / 255, brightness: p_brightnessValue / 255)
    }
} 