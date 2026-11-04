import SwiftUI
import AudioToolbox

struct ImageChoiceGameView: View {
    let options: [ImageChoiceOption]
    let correctIds: [String]
    let onSolve: () -> Void

    @State private var selected: Set<String> = []
    @State private var submitted = false
    @State private var wasWrong = false

    var isMultiSelect: Bool { correctIds.count > 1 }

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isMultiSelect ? "Select all that apply" : "Select the correct answer")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
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
                        optionCell(option)
                    }
                    .buttonStyle(SilentButtonStyle())
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
                    .disabled(selected.isEmpty)
            }
        }
    }

    @ViewBuilder
    private func optionCell(_ option: ImageChoiceOption) -> some View {
        let isSelected = selected.contains(option.id)
        let isWrongSelected = wasWrong && isSelected
        let borderColor: Color = isWrongSelected ? .red : (isSelected ? .blue : .clear)
        let bgColor: Color = isWrongSelected ? Color.red.opacity(0.25) : (isSelected ? Color.blue.opacity(0.25) : Color.white.opacity(0.07))

        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let url = option.imageUrl {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Color.primary.opacity(0.08)
                                    .overlay(ProgressView().tint(.secondary))
                            }
                        }
                    } else if let name = option.imageName {
                        Image(name).resizable().scaledToFill()
                    } else {
                        Color.primary.opacity(0.08)
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipped()

                if isSelected && !wasWrong {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .background(Circle().fill(.white).padding(2))
                        .padding(6)
                }
            }

            Text(option.label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity)
                .background(bgColor)
        }
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: 2)
        )
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

private struct SilentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
