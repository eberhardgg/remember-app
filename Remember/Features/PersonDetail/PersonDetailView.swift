import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let person: Person
    let onUpdate: () -> Void

    @State private var showingReview = false
    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Visual
                    visualImage
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 10)
                        .padding(.top, 24)

                    // Name
                    Text(person.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    // Context
                    if let context = person.context {
                        Label(context, systemImage: "mappin")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Keywords
                    if !person.descriptorKeywords.isEmpty {
                        KeywordTagsView(keywords: person.descriptorKeywords)
                            .padding(.horizontal)
                    }

                    // Description/transcript
                    if let transcript = person.transcriptText, !transcript.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(transcript)
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // Added date
                    Text("Added \(person.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Divider()
                        .padding(.horizontal)

                    // Review state
                    reviewStateSection

                    // Delete button
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)

                    Spacer()
                }
            }
            .navigationTitle("Details")
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
            .safeAreaInset(edge: .bottom) {
                Button {
                    showingReview = true
                } label: {
                    Label("Quiz me", systemImage: "brain.head.profile")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .sheet(isPresented: $showingReview) {
                ReviewSessionView(
                    reviewService: ReviewService(modelContext: modelContext),
                    singlePerson: person
                )
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

    private func deletePerson() {
        modelContext.delete(person)
        try? modelContext.save()
        onUpdate()
        dismiss()
    }

    @ViewBuilder
    private var visualImage: some View {
        if let url = person.preferredVisualURL,
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondary.opacity(0.2))
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                }
        }
    }

    private var reviewStateSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Review Status")
                    .font(.headline)
                Spacer()
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Next review")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(person.nextDueAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Interval")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(person.intervalDays) \(person.intervalDays == 1 ? "day" : "days")")
                        .font(.subheadline)
                }
            }

            if person.isDue {
                Label("Due for review", systemImage: "clock.badge.exclamationmark")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

#Preview {
    PersonDetailView(person: Person(name: "Sarah Chen", context: "Tech Conference"), onUpdate: {})
}
