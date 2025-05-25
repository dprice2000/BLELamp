//
//  ProminentBoldButtonStyle.swift
//  BLELamp
//
//  Created by David Price on 4/26/25.
//

import SwiftUI

/**
 * Public functions:
 * - makeBody(configuration:)
 */
struct ProminentBoldButtonStyle: ButtonStyle {
    var p_tint: Color = .accentColor

    /**
     * Creates a button view with bold font and increased font size, styled prominently.
     * @param configuration The properties of the button.
     * @return The styled button view.
     */
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 19, weight: .bold)) // Default is 17, so 17+2=19
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                configuration.isPressed
                ? p_tint.opacity(0.7)
                : p_tint
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
} 