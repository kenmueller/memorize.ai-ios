import Firebase

var reputationValues = [ReputationValue]()

class ReputationValue {
	let id: String
	var amount: Int
	var order: Int
	
	init(id: String, amount: Int, order: Int) {
		self.id = id
		self.amount = amount
		self.order = order
	}
	
	convenience init(_ snapshot: DocumentSnapshot) {
		self.init(
			id: snapshot.documentID,
			amount: snapshot.get("amount") as? Int ?? 0,
			order: snapshot.get("order") as? Int ?? 0
		)
	}
	
	static func loadAll() {
		firestore.collection("reputation").addSnapshotListener { snapshot, error in
			guard error == nil, let snapshot = snapshot?.documentChanges else { return }
			snapshot.forEach {
				let document = $0.document
				let documentId = document.documentID
				switch $0.type {
				case .added:
					ReputationValue(document).addToReputationValues()
					ChangeHandler.call(.reputationValueAdded)
				case .modified:
					get(documentId)?.update(document)
					ChangeHandler.call(.reputationValueModified)
				case .removed:
					remove(documentId)
					ChangeHandler.call(.reputationValueRemoved)
				@unknown default:
					break
				}
			}
		}
	}
	
	static func get(_ id: String) -> ReputationValue? {
		return reputationValues.first { $0.id == id }
	}
	
	static func remove(_ id: String) {
		reputationValues = reputationValues.filter { $0.id != id }
		sortReputationValues()
	}
	
	private static func sortReputationValues() {
		reputationValues.sort { $0.order < $1.order }
	}
	
	@discardableResult
	func addToReputationValues() -> ReputationValue {
		reputationValues.append(self)
		ReputationValue.sortReputationValues()
		return self
	}
	
	@discardableResult
	func update(_ snapshot: DocumentSnapshot) -> ReputationValue {
		amount = snapshot.get("amount") as? Int ?? amount
		order = snapshot.get("order") as? Int ?? order
		ReputationValue.sortReputationValues()
		return self
	}
}
