import SwiftUI
import CoreBluetooth

struct MainView: View {
	var body: some View {
		TabView {
			Tab("Configure", systemImage: "gearshape") {
				DevicesListView()
			}
		}
	}
}

#Preview {
	MainView()
		.environmentObject(BluetoothManager())
}
