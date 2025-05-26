//
//  DeveloperView.swift
//  BLELamp
//
//  Created by David Price on 4/26/25.
//

import SwiftUI
import Combine

/**
 * Public functions:
 * - body
 */
struct DeveloperView: View {
    @State private var t_logText: String = ""
    @State private var t_cancellable: AnyCancellable?
    @State private var t_scrollProxy: ScrollViewProxy? = nil
    @AppStorage("developerViewAutoScroll") private var t_autoScroll: Bool = false

    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Pull-down indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 6)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .center)

                // "Event Log" label
                Text("Event Log")
                    .font(.headline)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .center)

                // ScrollView with TextEditor
                ScrollViewReader { proxy in
                    ScrollView {
                        TextEditor(text: .constant(t_logText))
                            .frame(minHeight: geometry.size.height * 2 / 3)
                            .border(Color.gray.opacity(0.3), width: 1)
                            .padding(.horizontal, 16)
                            .allowsHitTesting(false) // Makes it read-only
                            .id("logContent") // ID for scrolling
                    }
                    .onAppear {
                        t_scrollProxy = proxy
                    }
                }

                // Auto-scroll toggle
                HStack {
                    Toggle("Auto-scroll", isOn: $t_autoScroll)
                        .padding(.horizontal, 16)
                    Spacer()
                }
                .padding(.top, 8)

                Spacer()
            }
            .onAppear {
                t_cancellable = Logger.shared.logPublisher
                    .receive(on: RunLoop.main)
                    .sink { newText in
                        t_logText = newText
                        // Only scroll if auto-scroll is enabled
                        if t_autoScroll {
                            withAnimation {
                                t_scrollProxy?.scrollTo("logContent", anchor: .bottom)
                            }
                        }
                    }
            }
            .onDisappear {
                t_cancellable?.cancel()
            }
        }
    }
} 