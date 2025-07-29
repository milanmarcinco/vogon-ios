//
//  ContentView.swift
//  Vogon
//
//  Created by Milan Marcinčo on 07/07/2025.
//

import SwiftUI
import CoreBluetooth

struct MainView: View {
	@StateObject private var bluetoothManager = BluetoothManager()
	
	var body: some View {
		TabView {
			Tab("Configure", systemImage: "gearshape") {
				DevicesListView()
			}
		}
		.environmentObject(bluetoothManager)
	}
}

#Preview {
	MainView()
}
