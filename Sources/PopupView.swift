import SwiftUI

struct PopupView: View {
    @Bindable private var manager = BedtimeManager.shared
    
    private var overtimeColor: Color {
        let _ = manager.currentTime
        return manager.shouldShowRed ? Color(red: 0.9, green: 0.2, blue: 0.2) : Color.primary
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header (Dynamic Countdown)
            VStack(spacing: 8) {
                Text(manager.formattedRemainingTime)
                    .font(.system(size: 38, weight: .bold, design: .monospaced))
                    .foregroundColor(overtimeColor)
                    .contentTransition(.numericText())
                    .animation(.default, value: manager.formattedRemainingTime)
                
                let r = manager.remainingTime
                if let eventName = r.eventName {
                    HStack(spacing: 4) {
                        Text("距离")
                        Text(eventName)
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                } else {
                    Text("无活跃倒计时")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 32)
            .padding(.bottom, 24)
            .background(
                LinearGradient(colors: [Color.primary.opacity(0.03), .clear], startPoint: .top, endPoint: .bottom)
            )
            
            Divider()

            // Scrollable Event List
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if manager.events.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "clock.badge.exclamationmark")
                                .font(.system(size: 32))
                                .foregroundStyle(.tertiary)
                            Text("尚未设置倒计时")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("点击下方按钮开启你的第一个提醒")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(manager.events) { event in
                            EventRow(event: Binding(
                                get: { manager.events.first(where: { $0.id == event.id }) ?? event },
                                set: { newValue in
                                    if let index = manager.events.firstIndex(where: { $0.id == event.id }) {
                                        manager.events[index] = newValue
                                    }
                                }
                            )) {
                                withAnimation(.spring(response: 0.3)) {
                                    manager.removeEvent(id: event.id)
                                }
                            }
                        }
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4)) {
                            manager.events.append(CountdownEvent(name: "新提醒", emoji: "🔔", hour: 22, minute: 0, repeatDays: [2,3,4,5,6]))
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("添加新提醒")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
                .padding(16)
            }
            .frame(height: 300) 

            Divider()

            // Global Preferences
            VStack(spacing: 12) {
                ToggleRow(title: "显示秒数", icon: "stopwatch", isOn: $manager.showSeconds)
                ToggleRow(title: "超时警报 (变红)", icon: "exclamationmark.triangle", isOn: $manager.warnWhenNear)
                ToggleRow(title: "紧凑菜单栏", icon: "menubar.rectangle", isOn: $manager.isCompactMode)
            }
            .padding(16)

            Divider()

            // Footer
            HStack {
                Button(action: {
                    withAnimation { manager.resetToDefaults() }
                }) {
                    Text("恢复默认")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Zzz v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.2.0")")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.02))
        }
        .frame(width: 320)
    }
}

struct ToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 13))
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
    @State private var showEmojiPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                EmojiPickerButton(emoji: $event.emoji)
                    .frame(width: 32, height: 32)

                TextField("提醒名称", text: $event.name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(event.isEnabled ? .primary : .secondary)

                Spacer()

                Toggle("", isOn: $event.isEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
            }

            // Row 2: Weekdays
            HStack(spacing: 4) {
                let days = ["日", "一", "二", "三", "四", "五", "六"]
                ForEach(1...7, id: \.self) { day in
                    let isSelected = event.repeatDays.contains(day)
                    Text(days[day-1])
                        .font(.system(size: 10, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isSelected ? Color.primary : Color.primary.opacity(0.05))
                        )
                        .foregroundStyle(isSelected ? Color(NSColor.windowBackgroundColor) : .secondary)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                if event.repeatDays.contains(day) {
                                    event.repeatDays.remove(day)
                                } else {
                                    event.repeatDays.insert(day)
                                }
                            }
                        }
                }
            }

            // Row 3: Time and Delete Button
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
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
                    .scaleEffect(0.95)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.04)))

                Spacer()

                Button(action: onDelete) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                        Text("删除")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.red.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }
}

struct EmojiPickerButton: View {
    @Binding var emoji: String
    @State private var showPicker = false

    var body: some View {
        Button(action: { showPicker = true }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
                Text(emoji)
                    .font(.system(size: 18))
            }
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPicker, arrowEdge: .bottom) {
            EmojiPickerView(selectedEmoji: $emoji, isPresented: $showPicker)
        }
    }
}

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Binding var isPresented: Bool
    @State private var searchText = ""

    private let categories: [(String, [String])] = [
        ("常用", ["🌙", "🔔", "⏰", "📚", "🏃", "💪", "🍎", "☕", "🍜", "🥗", "🛏️", "✈️", "🎯", "💡", "🔥", "❤️", "⭐", "🎉", "⚡", "🌈"]),
        ("表情", ["😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "😉", "😊", "😇", "🥰", "😍", "🤩", "😘", "😗", "😚", "😙", "🥲", "😋", "😛", "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🤫", "🤔", "🤐", "🤨", "😐", "😑", "😶", "😏", "😒", "🙄", "😬", "🤥"]),
        ("物品", ["⌚", "📱", "💻", "⌨️", "🖥️", "🖨️", "🖱️", "🖲️", "💽", "💾", "💿", "📀", "📼", "📷", "📸", "📹", "🎥", "📽️", "🎞️", "📞", "☎️", "📟", "📠", "📺", "📻", "🎙️", "🎚️", "🎛️", "🧭", "⏱️", "⏲️", "⏰", "🕰️", "⌛", "⏳", "📡", "🔋", "🔌", "💡", "🔦", "🕯️", "🧯"]),
        ("动物", ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷", "🐸", "🐵", "🐔", "🐧", "🐦", "🐤", "🦆", "🦅", "🦉", "🦇", "🐺", "🐗", "🐴", "🦄", "🐝", "🐛", "🦋", "🐌", "🐞", "🐜", "🦟", "🦗", "🐢", "🐍", "🦎", "🦖", "🦕", "🐙"]),
        ("食物", ["🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐", "🍈", "🍒", "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🥑", "🍆", "🥕", "🌽", "🥦", "🥬", "🥒", "🌶️", "🫑", "🧄", "🧅", "🥔", "🍠", "🥐", "🥯", "🍞", "🥖", "🧀", "🥚", "🍳", "🧈", "🥞", "🧇", "🥓", "🍔", "🍟", "🍕", "🌮", "🌯", "🥙", "🍝", "🍜", "🍲"]),
        ("活动", ["⚽", "🏀", "🏈", "⚾", "🥎", "🎾", "🏐", "🏉", "🥏", "🎱", "🏓", "🏸", "🏒", "🏑", "🥍", "🏏", "🪃", "🥅", "⛳", "🪁", "🏹", "🎣", "🤿", "🥊", "🥋", "🎽", "🛹", "🛼", "🛷", "⛸️", "🥌", "🎿", "⛷️", "🏂", "🪂", "🏋️", "🤼", "🤸", "🤺", "⛹️", "🤾", "🏌️", "🏇", "🧘", "🏄", "🏊", "🤽", "🚣", "🧗", "🚵", "🚴"]),
        ("旅行", ["🚗", "🚕", "🚙", "🚌", "🚎", "🏎️", "🚓", "🚑", "🚒", "🚐", "🛻", "🚚", "🚛", "🚜", "🦯", "🦽", "🦼", "🛴", "🚲", "🛵", "🏍️", "🛺", "🚨", "🚔", "🚍", "🚘", "🚖", "🚡", "🚠", "🚟", "🚃", "🚋", "🚞", "🚝", "🚄", "🚅", "🚈", "🚂", "🚆", "🚇", "🚊", "🚉", "✈️", "🛫", "🛬", "🛩️", "💺", "🛰️", "🚀", "🛸", "🚁", "🛶", "⛵", "🚤", "🛥️", "🛳️", "⛴️", "🚢"]),
        ("符号", ["❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟", "☮️", "✝️", "☪️", "🕉️", "☸️", "✡️", "🔯", "🕎", "☯️", "☦️", "🛐", "⛎", "♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐", "♑", "♒", "♓", "🆔", "⚛️", "🉑", "☢️", "☣️", "📴", "📳", "🈶", "🈚", "🈸", "🈺", "🈷️", "✴️", "🆚", "💮", "🉐", "㊙️", "㊗️", "🈴", "🈵", "🈹", "🈲", "🅰️", "🅱️", "🆎", "🆑", "🅾️", "🆘", "❌", "⭕", "🛑", "⛔", "📛", "🚫", "💯", "💢", "♨️", "🚷", "🚯", "🚳", "🚱", "🔞", "📵", "🚭", "❗", "❕", "❓", "❔", "‼️", "⁉️", "🔅", "🔆", "〽️", "⚠️", "🚸", "🔱", "⚜️", "🔰", "♻️", "✅", "🈯", "💹", "❇️", "✳️", "❎", "🌐", "💠", "Ⓜ️", "🌀", "💤", "🏧", "🚾", "♿", "🅿️", "🈳", "🈂️", "🛂", "🛃", "🛄", "🛅", "🚹", "🚺", "🚼", "⚧️", "🚻", "🚮", "🎦", "📶", "🈁", "🔣", "ℹ️", "🔤", "🔡", "🔠", "🆖", "🆗", "🆙", "🆒", "🆕", "🆓", "0️⃣", "1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣", "7️⃣", "8️⃣", "9️⃣", "🔟", "🔢", "#️⃣", "*️⃣", "⏏️", "▶️", "⏸️", "⏯️", "⏹️", "⏺️", "⏭️", "⏮️", "⏩", "⏪", "⏫", "⏬", "◀️", "🔼", "🔽", "➡️", "⬅️", "⬆️", "⬇️", "↗️", "↘️", "↙️", "↖️", "↕️", "↔️", "↪️", "↩️", "⤴️", "⤵️", "🔀", "🔁", "🔂", "🔄", "🔃", "🎵", "🎶", "➕", "➖", "➗", "✖️", "🟰", "♾️", "💲", "💱", "™️", "©️", "®️", "〰️", "➰", "➿", "🔚", "🔙", "🔛", "🔝", "🔜", "✔️", "☑️", "🔘", "🔴", "🟠", "🟡", "🟢", "🔵", "🟣", "⚫", "⚪", "🟤", "🔺", "🔻", "🔸", "🔹", "🔷", "🔶", "🔳", "🔲", "▪️", "▫️", "◾", "◽", "◼️", "◻️", "🟥", "🟧", "🟨", "🟩", "🟦", "🟪", "⬛", "⬜", "💭", "💤", "🐾", "👉", "👈", "👉", "☝️", "✋", "🤚", "🖐️", "🖖", "👌", "🤌", "🤏", "✌️", "🤞", "🤟", "🤘", "🤙", "👈", "👉", "👆", "🖕", "✍️", "🙏", "💅", "🤳", "💪", "🦾", "🦿", "🦵", "🦶", "👂", "🦻", "👃", "🧠", "🫀", "🫁", "🦷", "🦴", "👀", "👁️", "👅", "👄", "👶", "🧒", "👦", "👧", "🧑", "👱", "👨", "🧔", "👩", "🧓", "👴", "👵", "🙍", "🙎", "🙅", "🙆", "💁", "🙋", "🧏", "🙇", "🤦", "🤷", "👮", "🕵️", "💂", "🥷", "👷", "🤴", "👸", "👳", "👲", "🧕", "🤵", "👰", "🤰", "🤱", "👼", "🎒", "👑", "📿", "💄", "💍", "💎", "🐵", "🐒", "🦍", "🦧", "🐶", "🐕", "🦮", "🐩", "🐺", "🦊", "🦝", "🐱", "🐈", "🐈‍⬛", "🦁", "🐯", "🐅", "🐆", "🐴", "🦄", "🦓", "🦌", "🦬", "🐮", "🐂", "🐃", "🐄", "🐷", "🐖", "🐗", "🐽", "🐏", "🐑", "🐐", "🐪", "🐫", "🦒", "🦘", "🦥", "🦦", "🦨", "🦘", "🦡", "🐘", "🦛", "🦏", "🐭", "🐁", "🐀", "🐿️", "🦔", "🦇", "🐻", "🐻‍❄️", "🐨", "🐼", "🦥", "🦦", "🦨", "🦘", "🦡", "🐾", "🦃", "🐔", "🐓", "🐣", "🐤", "🐥", "🐦", "🐧", "🕊️", "🦅", "🦉", "🦇", "🦤", "🦆", "🦢", "🦩", "🦚", "🦜", "🦋", "🐛", "🐝", "🐞", "🦟", "🦗", "🕷️", "🕸️", "🦂", "🐢", "🐍", "🦎", "🦖", "🦕", "🐙", "🦑", "🦐", "🦞", "🦀", "🐡", "🐠", "🐟", "🐬", "🐳", "🐋", "🦈", "🐊", "🐅", "🐆", "🦓", "🦛", "🦏", "🐪", "🐫", "🦒", "🦘", "🦥"])
    ]

    private var filteredCategories: [(String, [String])] {
        if searchText.isEmpty {
            return categories
        }
        return categories.compactMap { category, emojis in
            let filtered = emojis.filter { $0.contains(searchText) || emojiName(for: $0).contains(searchText.lowercased()) }
            return filtered.isEmpty ? nil : (category, filtered)
        }
    }

    private func emojiName(for emoji: String) -> String {
        return emoji
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("搜索 Emoji...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(8)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(filteredCategories, id: \.0) { category, emojis in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 32))], spacing: 4) {
                                ForEach(emojis, id: \.self) { emoji in
                                    Button(action: {
                                        selectedEmoji = emoji
                                        isPresented = false
                                    }) {
                                        Text(emoji)
                                            .font(.system(size: 20))
                                            .frame(width: 32, height: 32)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 300, height: 320)
    }
}
