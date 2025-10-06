import Foundation
import SwiftUI

enum ConfigOptionValueType {
	case number
	case string
}

struct ConfigCollection {
	let name: String
	let sections: [ConfigSection]
}

struct ConfigSection {
	let id: UUID
	let name: String?
	let description: String?
	let options: [ConfigOption]
}

struct ConfigOption {
	let name: String
	let hint: String?
	let uuid: String
	let valueType: ConfigOptionValueType
	let disabled: Bool
}

typealias Config = [ConfigCollection]

let config: Config = [
	ConfigCollection(
		name: "⚙️ General",
		sections: [
			ConfigSection(
				id: UUID(),
				name: nil,
				description: "Amount of time asleep in minutes between sensor reads.",
				options: [
					ConfigOption(
						name: "Read interval",
						hint: "m",
						uuid: "0101",
						valueType: .number,
						disabled: false,
					)
				]
			)
		]
	),

	ConfigCollection(
		name: "🥵 Temp & humidity",
		sections: [
			ConfigSection(
				id: UUID(),
				name: nil,
				description: "Number of readings to average for each sensor read.",
				options: [
					ConfigOption(
						name: "Bulk size",
						hint: nil,
						uuid: "0201",
						valueType: .number,
						disabled: false,
					)
				]
			),

			ConfigSection(
				id: UUID(),
				name: nil,
				description: "Amount of time in seconds waiting between each reading in a bulk.",
				options: [
					ConfigOption(
						name: "Bulk sleep",
						hint: "s",
						uuid: "0202",
						valueType: .number,
						disabled: false,
					)
				]
			),
		]
	),

	ConfigCollection(
		name: "💩 Particulate matter",
		sections: [
			ConfigSection(
				id: UUID(),
				name: nil,
				description:
					"Amount of time in seconds the sensor needs to warm up before taking readings.",
				options: [
					ConfigOption(
						name: "Warm up time",
						hint: "s",
						uuid: "0203",
						valueType: .number,
						disabled: false,
					)
				]
			),

			ConfigSection(
				id: UUID(),
				name: nil,
				description: "Number of readings to average for each sensor read.",
				options: [
					ConfigOption(
						name: "Bulk size",
						hint: nil,
						uuid: "0204",
						valueType: .number,
						disabled: false,
					)
				]
			),

			ConfigSection(
				id: UUID(),
				name: nil,
				description: "Amount of time in seconds waiting between each reading in a bulk.",
				options: [
					ConfigOption(
						name: "Bulk sleep",
						hint: "s",
						uuid: "0205",
						valueType: .number,
						disabled: false,
					)
				]
			),
		]
	),

	ConfigCollection(
		name: "🛜 Synchronization",
		sections: [
			ConfigSection(
				id: UUID(),
				name: nil,
				description: nil,
				options: [
					ConfigOption(
						name: "WiFi name",
						hint: nil,
						uuid: "0701",
						valueType: .string,
						disabled: false,
					),

					ConfigOption(
						name: "WiFi password",
						hint: nil,
						uuid: "0702",
						valueType: .string,
						disabled: false,
					),
				]
			),

			ConfigSection(
				id: UUID(),
				name: nil,
				description: "The URL of the MQTT broker to send data to.",
				options: [
					ConfigOption(
						name: "MQTT broker URL",
						hint: nil,
						uuid: "0703",
						valueType: .string,
						disabled: true
					)
				]
			),
		]
	),
]
