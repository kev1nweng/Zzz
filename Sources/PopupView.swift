import SwiftUI

struct BlurFadeModifier: ViewModifier {
    let isIdentity: Bool
    func body(content: Content) -> some View {
        content
            .opacity(isIdentity ? 1 : 0)
            .blur(radius: isIdentity ? 0 : 5)
    }
}

extension AnyTransition {
    static var blurFade: AnyTransition {
        .modifier(
            active: BlurFadeModifier(isIdentity: false),
            identity: BlurFadeModifier(isIdentity: true)
        )
    }
}

struct PopupView: View {
    @Bindable private var manager = BedtimeManager.shared
    @State private var selectedTab = 0

    private var overtimeColor: Color {
        let _ = manager.currentTime
        return manager.shouldShowRed ? Color(red: 0.9, green: 0.2, blue: 0.2) : Color.primary
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                Text(manager.formattedRemainingTime)
                    .font(.system(size: 28, weight: .semibold, design: .monospaced))
                    .foregroundColor(overtimeColor)
                    .contentTransition(.numericText())
                    .animation(.default, value: manager.formattedRemainingTime)
                Text("距离就寝")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .animation(nil, value: manager.isOverrideActive)
            
            Divider()

            // Main Settings
            VStack(alignment: .leading, spacing: 16) {
                if manager.isOverrideActive {
                    HStack {
                        Text("临时就寝时间")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        DatePicker("", selection: $manager.overrideDate, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.field)
                            .labelsHidden()
                    }
                    .transition(.blurFade.animation(.easeInOut(duration: 0.2)))
                } else {
                    VStack(spacing: 16) {
                        Picker("", selection: $selectedTab) {
                            Text("工作日").tag(0)
                            Text("周末").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        
                        HStack {
                            Text("常规就寝时间")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if selectedTab == 0 {
                                DatePicker("", selection: $manager.weekdayDate, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.field)
                                    .labelsHidden()
                            } else {
                                DatePicker("", selection: $manager.weekendDate, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.field)
                                    .labelsHidden()
                            }
                        }
                    }
                    .transition(.blurFade.animation(.easeInOut(duration: 0.2)))
                }
            }
            .padding(16)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: manager.isOverrideActive)

            Divider()

            // Global Preferences
            VStack(spacing: 12) {
                HStack {
                    Text("显示秒数")
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: $manager.showSeconds)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                }
                
                HStack {
                    Text("超时变红")
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: $manager.warnWhenNear)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                }
            }
            .padding(16)

            // Footer
            HStack {
                Button("恢复默认") {
                    manager.resetToDefaults()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)
                
                Spacer()

                Toggle("临时覆盖", isOn: $manager.isOverrideActive)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                
                Text("覆盖今天")
                    .font(.caption)
                    .foregroundStyle(manager.isOverrideActive ? .primary : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.unemphasizedSelectedContentBackgroundColor).opacity(0.3))
        }
        .frame(width: 260)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: manager.isOverrideActive)
    }
}
