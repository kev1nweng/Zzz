import SwiftUI

struct PopupView: View {
    @Bindable private var manager = BedtimeManager.shared
    
    private var overtimeColor: Color {
        let _ = manager.currentTime
        return manager.shouldShowRed ? Color(red: 0.9, green: 0.2, blue: 0.2) : Color.primary
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header (Fixed)
            VStack(spacing: 6) {
                Text(manager.formattedRemainingTime)
                    .font(.system(size: 32, weight: .semibold, design: .monospaced))
                    .foregroundColor(overtimeColor)
                    .contentTransition(.numericText())
                    .animation(.default, value: manager.formattedRemainingTime)
                
                let r = manager.remainingTime
                if let eventName = r.eventName {
                    Text("距离 \(eventName)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("无活跃倒计时")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            
            Divider()

            // Scrollable Event List
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if manager.events.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "clock.badge.exclamationmark")
                                .font(.system(size: 32))
                                .foregroundStyle(.tertiary)
                            Text("无倒计时点")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("点击下方按钮添加一个提醒")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Using ID-based ForEach is safest for removals
                        ForEach(manager.events) { event in
                            if let binding = binding(for: event.id) {
                                EventRow(event: binding) {
                                    withAnimation(.spring(response: 0.3)) {
                                        manager.removeEvent(id: event.id)
                                    }
                                }
                            }
                        }
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            manager.events.append(CountdownEvent(id: UUID(), name: "新提醒", hour: 22, minute: 0, repeatDays: [2,3,4,5,6], isEnabled: true))
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("添加倒计时")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 4)
                }
                .padding(16)
            }
            .frame(height: 240) 

            Divider()

            // Global Preferences (Fixed outside scroll)
            VStack(spacing: 16) {
                ToggleRow(title: "显示秒数", isOn: $manager.showSeconds)
                ToggleRow(title: "超时变红", isOn: $manager.warnWhenNear)
                ToggleRow(title: "紧凑模式", isOn: $manager.isCompactMode)
            }
            .padding(16)

            Divider()

            // Footer (Fixed)
            HStack {
                Button("恢复默认") {
                    withAnimation {
                        manager.resetToDefaults()
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)
                
                Spacer()
                
                Text("Zzz v0.1.0")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.03))
        }
        .frame(width: 280)
    }
    
    private func binding(for id: UUID) -> Binding<CountdownEvent>? {
        guard let index = manager.events.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { manager.events[index] },
            set: { manager.events[index] = $0 }
        )
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
    }
}

struct EventRow: View {
    @Binding var event: CountdownEvent
    var onDelete: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Toggle("", isOn: $event.isEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                
                TextField("名称", text: $event.name)
                    .textFieldStyle(.plain)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(event.isEnabled ? .primary : .secondary)
                
                Spacer()
                
                DatePicker("", selection: Binding(
                    get: { event.timeDate },
                    set: { newValue in
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                        event.hour = comps.hour ?? 0
                        event.minute = comps.minute ?? 0
                    }
                ), displayedComponents: .hourAndMinute)
                .datePickerStyle(.field)
                .labelsHidden()
                .scaleEffect(0.9)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(.red.opacity(0.6))
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red.opacity(0.05))
                        )
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 0) {
                let days = ["日", "一", "二", "三", "四", "五", "六"]
                ForEach(1...7, id: \.self) { day in
                    let isSelected = event.repeatDays.contains(day)
                    Text(days[day-1])
                        .font(.system(size: 11, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isSelected ? Color.primary : Color.primary.opacity(0.04))
                        )
                        .foregroundStyle(isSelected ? Color(NSColor.windowBackgroundColor) : .secondary)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.2)) {
                                if event.repeatDays.contains(day) {
                                    event.repeatDays.remove(day)
                                } else {
                                    event.repeatDays.insert(day)
                                }
                            }
                        }
                    
                    if day < 7 {
                        Spacer(minLength: 4)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(isHovering ? 0.03 : 0.015))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}
