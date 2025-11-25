import SwiftUI

struct MemeTextOverlay: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 28, weight: .heavy))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .shadow(color: .black, radius: 1, x: 2, y: 2)
            .shadow(color: .black, radius: 1, x: -2, y: -2)
            .lineLimit(nil)
            .minimumScaleFactor(0.5)
    }
}
