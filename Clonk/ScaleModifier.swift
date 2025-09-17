import SwiftUI

struct ScaleModifier: ViewModifier {
	let x: CGFloat
	let y: CGFloat

	func body(content: Content) -> some View {
		content.scaleEffect(x: x, y: y, anchor: .center)
	}
}