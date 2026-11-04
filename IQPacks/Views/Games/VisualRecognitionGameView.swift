import SwiftUI
import AudioToolbox

private let storageBase = "https://lwynbkpmizbymgixrmgt.supabase.co/storage/v1/object/public/pack-images/"

struct VisualRecognitionGameView: View {
    let imageIds: [String]
    let options: [RecognitionOption]
    let correctId: String
    let explanation: String?
    let onSolve: () -> Void

    @State private var selected: String? = nil
    @State private var submitted = false
    @State private var wasWrong = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !imageIds.isEmpty {
                imageStrip
            }

            Text("Which is it?")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

            VStack(spacing: 8) {
                ForEach(options) { option in
                    Button {
                        guard !submitted else { return }
                        selected = option.id
                        FeedbackHelper.select()
                        if wasWrong { wasWrong = false }
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .stroke(selected == option.id ? Color.blue : Color.secondary, lineWidth: 1.5)
                                .frame(width: 20, height: 20)
                                .overlay {
                                    if selected == option.id {
                                        Circle().fill(Color.blue).frame(width: 12, height: 12)
                                    }
                                }

                            Text(option.label)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(12)
                        .background(optionBackground(for: option.id), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            if submitted {
                Color.clear.frame(height: 0)
            } else {
                if wasWrong {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                        Text("Not quite — try again")
                            .font(.subheadline).fontWeight(.medium).foregroundStyle(.white)
                    }
                }
                Button("Submit") { submit() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(selected == nil)
            }
        }
    }

    @ViewBuilder
    private var imageStrip: some View {
        if imageIds.count == 1, let imageId = imageIds.first,
           let url = URL(string: "\(storageBase)\(imageId).png") {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                default:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.07))
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .overlay(ProgressView().tint(.secondary))
                }
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(imageIds, id: \.self) { imageId in
                        if let url = URL(string: "\(storageBase)\(imageId).png") {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 160)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                default:
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.07))
                                        .frame(width: 200, height: 160)
                                        .overlay(ProgressView().tint(.secondary))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func optionBackground(for id: String) -> Color {
        if wasWrong && selected == id { return Color.red.opacity(0.25) }
        return selected == id ? Color.blue.opacity(0.25) : Color.white.opacity(0.07)
    }

    private func submit() {
        if selected == correctId {
            submitted = true
            FeedbackHelper.correct()
            onSolve()
        } else {
            wasWrong = true
            FeedbackHelper.wrong()
        }
    }
}
