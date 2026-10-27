import SwiftUI

struct MainView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("stahpwatch").font(.system(size: 40, weight: .bold)).foregroundStyle(.white)
        }
    }
}
