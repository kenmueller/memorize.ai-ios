final class Deck: Identifiable, Equatable {
	let id: String
	var name: String
	
	init(id: String, name: String) {
		self.id = id
		self.name = name
	}
	
	static func == (lhs: Deck, rhs: Deck) -> Bool {
		lhs.id == rhs.id
	}
}
