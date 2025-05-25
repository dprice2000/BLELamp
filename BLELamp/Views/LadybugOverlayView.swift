import SwiftUI

/**
 * Public functions:
 * - body
 */
struct LadybugOverlayView: View {
    @State private var t_showDeveloperView = false

    var body: some View {
        VStack {
            HStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemBackground).opacity(0.8))
                        )
                        .frame(width: 55, height: 55)
                    Button(action: {
                        t_showDeveloperView = true
                    }) {
                        Image(systemName: "ladybug.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 35, height: 35)
                            .foregroundColor(.red)
                    }
                    .frame(width: 45, height: 45)
                }
                .frame(width: 55, height: 55)
                .shadow(radius: 4)
                .padding(.top, 8)
                .padding(.trailing, 8)
            }
            Spacer()
        }
        .sheet(isPresented: $t_showDeveloperView) {
            DeveloperView()
        }
        .allowsHitTesting(true)
    }
} 