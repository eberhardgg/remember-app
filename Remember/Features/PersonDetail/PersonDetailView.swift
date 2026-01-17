import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let person: Person
    let onUpdate: () -> Void

    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Name - large and prominent at top
                    Text(person.name)
                        .font(.system(size: 34, weight: .bold))
                        .padding(.top, 24)
                        .padding(.bottom, 20)

                    // Visual - Polaroid style card
                    visualCard
                        .padding(.horizontal, 40)

                    // Combined description (context + transcript)
                    combinedDescriptionSection
                        .padding(.top, 24)
                        .padding(.horizontal, 24)

                    // Metadata footer
                    VStack(spacing: 16) {
                        Divider()
                            .padding(.horizontal, 24)

                        Text("Added \(person.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Text("Delete")
                                .font(.subheadline)
                        }
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 32)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showingEdit = true
                    }
                }
            }
            .sheet(isPresented: $showingEdit) {
                PersonEditView(person: person, onSave: {
                    onUpdate()
                })
            }
            .alert("Delete \(person.name)?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deletePerson()
                }
            } message: {
                Text("This cannot be undone.")
            }
        }
    }

    // MARK: - Visual Card (Polaroid style)

    @ViewBuilder
    private var visualCard: some View {
        VStack(spacing: 0) {
            // Image area
            visualImage
                .frame(height: 260)
                .clipped()

            // White bottom area (Polaroid style)
            if let meaning = person.nameMeaning {
                Text(meaning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var visualImage: some View {
        if let url = person.preferredVisualURL,
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
        } else {
            Rectangle()
                .fill(Color(.secondarySystemBackground))
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                }
        }
    }

    // MARK: - Combined Description Section

    @ViewBuilder
    private var combinedDescriptionSection: some View {
        let transcriptText = person.editedDescription ?? person.transcriptText
        let context = person.context

        // Build combined text: "Context. Transcript" or just one if other is empty
        let combinedText: String? = {
            let parts = [context, transcriptText].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: ". ")
        }()

        if let text = combinedText {
            let keywords = person.highlightKeywords.isEmpty ? person.descriptorKeywords : person.highlightKeywords
            HighlightedText(text: text, keywords: keywords, font: .body, color: .primary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func deletePerson() {
        modelContext.delete(person)
        try? modelContext.save()
        onUpdate()
        dismiss()
    }
}

#Preview {
    PersonDetailView(person: Person(name: "Sarah Chen", context: "Tech Conference"), onUpdate: {})
}
