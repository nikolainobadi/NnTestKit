import SwiftUI

struct CheckoutView: View {
    @State private var cardNumber = ""
    @State private var orderPlaced = false

    var body: some View {
        Form {
            Section("Payment") { TextField("Card number", text: $cardNumber) }
            Button("Place Order") { orderPlaced = true }
        }
        .navigationTitle("Checkout")
        .alert("Order placed", isPresented: $orderPlaced) { Button("OK") { } }
    }
}
