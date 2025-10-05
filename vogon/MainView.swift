import CoreBluetooth
import SwiftUI

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
