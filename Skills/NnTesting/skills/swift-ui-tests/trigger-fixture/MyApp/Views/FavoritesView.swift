import SwiftUI

struct FavoritesView: View {
    @State private var favorites = ["Coffee", "Tea", "Juice"]
    @State private var pendingDelete: String?

    var body: some View {
        List {
            ForEach(favorites, id: \.self) { item in
                Text(item)
                    .swipeActions { Button("Delete", role: .destructive) { pendingDelete = item } }
            }
        }
        .navigationTitle("Favorites")
        .alert("Remove favorite?", isPresented: .constant(pendingDelete != nil)) {
            Button("Remove", role: .destructive) { favorites.removeAll(where: { $0 == pendingDelete }); pendingDelete = nil }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        }
    }
}
