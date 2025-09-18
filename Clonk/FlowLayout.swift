import SwiftUI

struct FlowLayout: Layout {
	var spacing: CGFloat

	init(spacing: CGFloat = 8) {
		self.spacing = spacing
	}

	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
		return layout(sizes: sizes, proposal: proposal).size
	}

	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
		let positions = layout(sizes: sizes, proposal: proposal).positions

		for (index, subview) in subviews.enumerated() {
			subview.place(at: CGPoint(x: bounds.minX + positions[index].x, y: bounds.minY + positions[index].y), proposal: .unspecified)
		}
	}

	private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (size: CGSize, positions: [CGPoint]) {
		let maxWidth = proposal.width ?? .infinity
		var positions: [CGPoint] = []
		var currentRowWidth: CGFloat = 0
		var currentRowHeight: CGFloat = 0
		var totalHeight: CGFloat = 0
		var currentY: CGFloat = 0

		for (index, size) in sizes.enumerated() {
			if currentRowWidth + size.width > maxWidth && currentRowWidth > 0 {
				// Start new row
				totalHeight += currentRowHeight + spacing
				currentY += currentRowHeight + spacing
				currentRowWidth = 0
				currentRowHeight = 0
			}

			positions.append(CGPoint(x: currentRowWidth, y: currentY))
			currentRowWidth += size.width + (index < sizes.count - 1 ? spacing : 0)
			currentRowHeight = max(currentRowHeight, size.height)
		}

		totalHeight += currentRowHeight

		return (CGSize(width: min(currentRowWidth, maxWidth), height: totalHeight), positions)
	}
}
