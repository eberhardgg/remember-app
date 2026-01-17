import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void
    var size: Size = .large

    enum Size {
        case large
        case compact

        var buttonSize: CGFloat {
            switch self {
            case .large: return Sizing.RecordButton.main
            case .compact: return Sizing.RecordButton.compact
            }
        }

        var pulseSize: CGFloat {
            switch self {
            case .large: return Sizing.RecordButton.pulse
            case .compact: return Sizing.RecordButton.pulseCompact
            }
        }

        var stopIconSize: CGFloat {
            switch self {
            case .large: return Sizing.RecordButton.stopIcon
            case .compact: return Sizing.RecordButton.stopIconCompact
            }
        }

        var stopIconRadius: CGFloat {
            switch self {
            case .large: return 8
            case .compact: return 6
            }
        }

        var micFont: Font {
            switch self {
            case .large: return Typography.micIconLarge
            case .compact: return Typography.micIconMedium
            }
        }

        var shadowRadius: CGFloat {
            switch self {
            case .large: return Shadow.medium
            case .compact: return Shadow.small
            }
        }

        var recordingShadowRadius: CGFloat {
            switch self {
            case .large: return Shadow.large
            case .compact: return 8
            }
        }
    }

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
                        .fill(Color.rememberRecording.opacity(0.3))
                        .frame(width: size.pulseSize, height: size.pulseSize)
                        .scaleEffect(pulseScale)
                }

                // Main button
                Circle()
                    .fill(isRecording ? Color.rememberRecording : Color.accentColor)
                    .frame(width: size.buttonSize, height: size.buttonSize)
                    .shadow(radius: isRecording ? size.recordingShadowRadius : size.shadowRadius)

                // Icon
                if isRecording {
                    RoundedRectangle(cornerRadius: size.stopIconRadius)
                        .fill(.white)
                        .frame(width: size.stopIconSize, height: size.stopIconSize)
                } else {
                    Image(systemName: "mic.fill")
                        .font(size.micFont)
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .recordButtonAccessibility(isRecording: isRecording)
        .animation(.easeInOut(duration: Timing.quick), value: isRecording)
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startPulseAnimation()
            } else {
                pulseScale = 1.0
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: Timing.pulse).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }
    }
}

#Preview {
    VStack(spacing: Spacing.xxl) {
        VStack {
            Text("Large").font(.caption)
            RecordButton(isRecording: false, action: {})
        }
        VStack {
            Text("Large Recording").font(.caption)
            RecordButton(isRecording: true, action: {})
        }
        VStack {
            Text("Compact").font(.caption)
            RecordButton(isRecording: false, action: {}, size: .compact)
        }
        VStack {
            Text("Compact Recording").font(.caption)
            RecordButton(isRecording: true, action: {}, size: .compact)
        }
    }
}
