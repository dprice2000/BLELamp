//
//  DeveloperView.swift
//  BLELamp
//
//  Created by David Price on 4/26/25.
//

import SwiftUI

/**
 * Public functions:
 * - body
 */
struct DeveloperView: View {
    var body: some View {
        VStack {
            // Pull-down indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 6)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .center)

            Text("Developer Console")
                .font(.largeTitle)
                .padding()
            Spacer()
        }
    }
} 