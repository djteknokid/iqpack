import SwiftUI

struct PronunciationGameView: View {
    let audioUrl: String
    let phonetic: String?
    let definition: String?
    let onSolve: () -> Void

    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let phonetic {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .foregroundStyle(.secondary)
                    Text(phonetic)
                        .font(.title3)
                        .fontDesign(.serif)
                        .foregroundStyle(.primary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            }

            Link(destination: URL(string: audioUrl)!) {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundStyle(.blue)
                    Text("Listen to Pronunciation")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            if !revealed {
                Button("Reveal Definition") {
                    revealed = true
                    onSolve()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            } else if let definition {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Definition")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(definition)
                        .font(.subheadline)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            }

            Button {
                onSolve()
            } label: {
                Label("Mark as Learned", systemImage: "checkmark")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
    }
}
