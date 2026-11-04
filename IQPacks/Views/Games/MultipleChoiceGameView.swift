import SwiftUI
import AudioToolbox

struct MultipleChoiceGameView: View {
    let options: [ChoiceOption]
    let correctIds: [String]
    let mediaUrl: String?
    let onSolve: () -> Void

    @State private var selected: Set<String> = []
    @State private var submitted = false
    @State private var wasWrong = false

    var isMultiSelect: Bool { correctIds.count > 1 }

    private var isImageUrl: Bool {
        guard let url = mediaUrl?.lowercased() else { return false }
        return url.hasSuffix(".png") || url.hasSuffix(".jpg") || url.hasSuffix(".jpeg") || url.hasSuffix(".webp")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let urlString = mediaUrl, let url = URL(string: urlString) {
                if isImageUrl {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        default:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.07))
                                .aspectRatio(1, contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .overlay(ProgressView().tint(.white.opacity(0.4)))
                        }
                    }
                } else {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundStyle(.red)
                            Text("Watch / Listen")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(isMultiSelect ? "Select all that apply" : "Select the correct answer")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

            VStack(spacing: 8) {
                ForEach(options) { option in
                    Button {
                        guard !submitted else { return }
                        if isMultiSelect {
                            if selected.contains(option.id) {
                                selected.remove(option.id)
                            } else {
                                selected.insert(option.id)
                            }
                        } else {
                            selected = [option.id]
                        }
                        FeedbackHelper.select()
                        if wasWrong { wasWrong = false }
                    } label: {
                        HStack(spacing: 12) {
                            optionIndicator(for: option.id)
                            Text(option.text)
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
                // Correct state — CardGameView overlay handles the celebration UI
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
                    .disabled(selected.isEmpty)
            }
        }
    }

    private func optionIndicator(for id: String) -> some View {
        ZStack {
            if isMultiSelect {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(selected.contains(id) ? Color.blue : Color.secondary, lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                if selected.contains(id) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            } else {
                Circle()
                    .stroke(selected.contains(id) ? Color.blue : Color.secondary, lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                if selected.contains(id) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                }
            }
        }
    }

    private func optionBackground(for id: String) -> Color {
        if wasWrong && selected.contains(id) { return Color.red.opacity(0.25) }
        return selected.contains(id) ? Color.blue.opacity(0.25) : Color.white.opacity(0.07)
    }

    private func submit() {
        if Set(correctIds) == selected {
            submitted = true
            FeedbackHelper.correct()
            onSolve()
        } else {
            wasWrong = true
            FeedbackHelper.wrong()
        }
    }
}
