import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button {
            if isRecording {
                HapticFeedback.recordingStopped()
                AccessibilityAnnouncement.recordingStopped()
            } else {
                HapticFeedback.recordingStarted()
                AccessibilityAnnouncement.recordingStarted()
            }
            action()
        } label: {
            ZStack {
                // Pulse animation when recording
                if isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseScale)
                }

                // Main button
                Circle()
                    .fill(isRecording ? Color.red : Color.accentColor)
                    .frame(width: 100, height: 100)
                    .shadow(radius: isRecording ? 10 : 5)

                // Icon
                if isRecording {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .recordButtonAccessibility(isRecording: isRecording)
        .animation(.easeInOut(duration: 0.2), value: isRecording)
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startPulseAnimation()
            } else {
                pulseScale = 1.0
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        RecordButton(isRecording: false, action: {})
        RecordButton(isRecording: true, action: {})
    }
}
