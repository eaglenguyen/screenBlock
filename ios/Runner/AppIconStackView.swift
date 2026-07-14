import SwiftUI
import FamilyControls
import ManagedSettings

@available(iOS 16.0, *)
struct AppIconStackView: View {
    let tokens: Set<ApplicationToken>
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let firstToken = tokens.first {
                Label(firstToken)
                    .labelStyle(.iconOnly)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.27))
            } else {
                RoundedRectangle(cornerRadius: size * 0.27)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size, height: size)
            }

            if tokens.count > 1 {
                Text("+\(tokens.count - 1)")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(Color(red: 26/255, green: 18/255, blue: 8/255))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(red: 237/255, green: 184/255, blue: 42/255))
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color(red: 30/255, green: 30/255, blue: 53/255), lineWidth: 1.5)
                    )
            }
        }
        .frame(width: size, height: size) // extra room so the badge doesn't get clipped
    }
}
