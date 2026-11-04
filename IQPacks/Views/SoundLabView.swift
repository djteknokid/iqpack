import SwiftUI
import AudioToolbox

struct SoundLabView: View {
    // Curated list of IDs known to have audible sound on device
    private let groups: [(String, [SystemSoundID])] = [
        ("Tones & Chimes", [1000, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, 1012, 1013, 1014, 1015, 1016]),
        ("Alerts & Notifications", [1020, 1021, 1022, 1023, 1024, 1025, 1026, 1027, 1028, 1029, 1030, 1031, 1032]),
        ("Clicks & UI", [1050, 1051, 1052, 1053, 1054, 1055, 1056, 1057, 1058, 1059]),
        ("Keyboard & Taps", [1100, 1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1114, 1115, 1116, 1117, 1118, 1119, 1120, 1121, 1122, 1123, 1124, 1125, 1126]),
        ("Mail & Messages", [1150, 1151, 1152, 1153, 1154, 1155, 1156, 1157, 1158, 1159, 1160, 1161, 1162, 1163, 1165, 1166, 1167, 1168, 1169]),
        ("Camera & Misc", [1108, 1200, 1201, 1202, 1203, 1204, 1205, 1206, 1207, 1208, 1209, 1210, 1211, 1306, 1307, 1308, 1309, 1310, 1311, 1312, 1313, 1314, 1315]),
    ]

    @State private var playing: SystemSoundID? = nil

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tap to play. Turn volume up — some are quiet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Current sounds: tap=1123  tick=1104  correct=1025  wrong=1053  match=1057")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospaced()
                }
            }

            ForEach(groups, id: \.0) { label, ids in
                Section(label) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(ids, id: \.self) { id in
                            Button {
                                playing = id
                                AudioServicesPlaySystemSound(id)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if playing == id { playing = nil }
                                }
                            } label: {
                                Text("\(id)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(playing == id ? .black : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(playing == id ? Color.yellow : Color(.systemGray6), in: RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Sound Lab")
        .navigationBarTitleDisplayMode(.inline)
    }
}
