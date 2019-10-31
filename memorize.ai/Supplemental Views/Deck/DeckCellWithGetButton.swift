import SwiftUI

struct DeckCellWithGetButton: View {
	let deck: Deck
	let width: CGFloat
	
	var body: some View {
		DeckCell(
			deck: deck,
			width: width
		) {
			CustomRectangle(
				background: Color.darkBlue,
				cornerRadius: 8
			) {
				Text("GET")
			}
		}
	}
}

#if DEBUG
struct DeckCellWithGetButton_Previews: PreviewProvider {
	static var previews: some View {
		DeckCellWithGetButton(
			deck: .init(
				id: "0",
				name: "Geometry Prep",
				subtitle: "Angles, lines, triangles and other polygons",
				numberOfViews: 1000000000,
				numberOfUniqueViews: 200000,
				numberOfRatings: 12400,
				averageRating: 4.5,
				numberOfDownloads: 196400
			),
			width: 165
		)
	}
}
#endif
