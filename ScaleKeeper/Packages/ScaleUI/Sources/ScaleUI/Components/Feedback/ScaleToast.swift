import SwiftUI

// MARK: - Toast Type

public enum ScaleToastType {
    case success
    case error
    case warning
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .scaleSuccess
        case .error: return .scaleError
        case .warning: return .scaleWarning
        case .info: return .scaleInfo
        }
    }
}

// MARK: - Toast Item

public struct ScaleToastItem: Identifiable, Equatable {
    public let id = UUID()
    public let type: ScaleToastType
    public let message: String
    public let duration: Double

    public init(type: ScaleToastType, message: String, duration: Double = 3.0) {
        self.type = type
        self.message = message
        self.duration = duration
    }

    public static func == (lhs: ScaleToastItem, rhs: ScaleToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast View

public struct ScaleToastView: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let toast: ScaleToastItem
    var onDismiss: (() -> Void)? = nil

    public init(toast: ScaleToastItem, onDismiss: (() -> Void)? = nil) {
        self.toast = toast
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: ScaleSpacing.sm) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 20))
                .foregroundStyle(toast.type.color)

            Text(toast.message)
                .font(Font.scaleBody)
                .foregroundStyle(Color.scaleTextPrimary)
                .lineLimit(2)

            Spacer()

            Button {
                onDismiss?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(themeManager.currentTheme.textTertiary)
            }
        }
        .padding(.horizontal, ScaleSpacing.md)
        .padding(.vertical, ScaleSpacing.sm)
        .background(themeManager.currentTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: ScaleRadius.md)
                .stroke(toast.type.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Toast Manager

@MainActor
public class ScaleToastManager: ObservableObject {
    public static let shared = ScaleToastManager()

    @Published public var currentToast: ScaleToastItem?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    public func show(_ type: ScaleToastType, message: String, duration: Double = 3.0) {
        dismissTask?.cancel()

        withAnimation(ScaleAnimation.medium) {
            currentToast = ScaleToastItem(type: type, message: message, duration: duration)
        }

        // Haptic feedback
        switch type {
        case .success: ScaleHaptics.success()
        case .error: ScaleHaptics.error()
        case .warning: ScaleHaptics.warning()
        case .info: ScaleHaptics.light()
        }

        // Auto dismiss
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                await MainActor.run {
                    self.dismiss()
                }
            }
        }
    }

    public func dismiss() {
        dismissTask?.cancel()
        withAnimation(ScaleAnimation.medium) {
            currentToast = nil
        }
    }

    // Convenience methods
    public func success(_ message: String) {
        show(.success, message: message)
    }

    public func error(_ message: String) {
        show(.error, message: message)
    }

    public func warning(_ message: String) {
        show(.warning, message: message)
    }

    public func info(_ message: String) {
        show(.info, message: message)
    }
}

// MARK: - Toast Container Modifier

public struct ScaleToastContainer: ViewModifier {
    @ObservedObject var toastManager = ScaleToastManager.shared

    public func body(content: Content) -> some View {
        ZStack {
            content

            VStack {
                if let toast = toastManager.currentToast {
                    ScaleToastView(toast: toast) {
                        toastManager.dismiss()
                    }
                    .padding(.horizontal, ScaleSpacing.md)
                    .padding(.top, ScaleSpacing.md)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()
            }
        }
    }
}

public extension View {
    func scaleToastContainer() -> some View {
        modifier(ScaleToastContainer())
    }
}

// MARK: - Alert Dialog

public struct ScaleAlertDialog: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let title: String
    let message: String
    var primaryButton: String = "OK"
    var secondaryButton: String? = nil
    var destructive: Bool = false
    var onPrimary: () -> Void
    var onSecondary: (() -> Void)? = nil

    public init(
        title: String,
        message: String,
        primaryButton: String = "OK",
        secondaryButton: String? = nil,
        destructive: Bool = false,
        onPrimary: @escaping () -> Void,
        onSecondary: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.destructive = destructive
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
    }

    public var body: some View {
        VStack(spacing: ScaleSpacing.lg) {
            VStack(spacing: ScaleSpacing.sm) {
                Text(title)
                    .font(Font.scaleTitle3)
                    .foregroundStyle(Color.scaleTextPrimary)

                Text(message)
                    .font(Font.scaleBody)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let secondary = secondaryButton {
                HStack(spacing: ScaleSpacing.sm) {
                    Button {
                        onSecondary?()
                    } label: {
                        Text(secondary)
                            .font(Font.scaleButton)
                            .foregroundStyle(themeManager.currentTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ScaleSpacing.sm)
                            .background(themeManager.currentTheme.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                    }

                    Button {
                        onPrimary()
                    } label: {
                        Text(primaryButton)
                            .font(Font.scaleButton)
                            .foregroundStyle(destructive ? Color.white : themeManager.currentTheme.backgroundPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ScaleSpacing.sm)
                            .background(destructive ? Color.scaleError : themeManager.currentTheme.primaryAccent)
                            .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                    }
                }
            } else {
                Button {
                    onPrimary()
                } label: {
                    Text(primaryButton)
                        .font(Font.scaleButton)
                        .foregroundStyle(themeManager.currentTheme.backgroundPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ScaleSpacing.sm)
                        .background(themeManager.currentTheme.primaryAccent)
                        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                }
            }
        }
        .padding(ScaleSpacing.lg)
        .background(themeManager.currentTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.lg))
        .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
        .padding(.horizontal, ScaleSpacing.xl)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ScaleBackground()

        VStack(spacing: ScaleSpacing.xl) {
            ScaleToastView(toast: ScaleToastItem(type: .success, message: "Animal saved successfully!"))
            ScaleToastView(toast: ScaleToastItem(type: .error, message: "Failed to save. Please try again."))
            ScaleToastView(toast: ScaleToastItem(type: .warning, message: "This animal is overdue for feeding"))
            ScaleToastView(toast: ScaleToastItem(type: .info, message: "Tip: Tap and hold for more options"))

            Spacer()

            ScaleAlertDialog(
                title: "Delete Animal?",
                message: "This action cannot be undone. All feeding records and photos will be permanently deleted.",
                primaryButton: "Delete",
                secondaryButton: "Cancel",
                destructive: true,
                onPrimary: {},
                onSecondary: {}
            )
        }
        .padding()
    }
}
