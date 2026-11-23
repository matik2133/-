import SwiftUI

@main
struct ParyApp: App {
    @StateObject private var store = Store()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(store)
        }
    }
}
