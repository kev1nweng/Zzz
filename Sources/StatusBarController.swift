import AppKit
import SwiftUI
import Observation

final class StatusBarController: NSObject {
    private let manager = BedtimeManager.shared
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private var timer: Timer?

    override init() {
        super.init()
        configureStatusItem()
        configurePopover()
        
        // 使用 withObservationTracking 监听 BedtimeManager 的变化
        startObservation()
        
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    private func startObservation() {
        withObservationTracking {
            _ = manager.events
            _ = manager.isCompactMode
            _ = manager.showSeconds
            _ = manager.warnWhenNear
            _ = manager.currentTime
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.refresh()
                self?.startObservation() // 重新订阅
            }
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleStatusItemClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.title = ""
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 320, height: 480)
        popover.contentViewController = NSHostingController(rootView: PopupView())
    }

    func refresh() {
        guard let button = statusItem.button else { return }

        let rawText = manager.formattedRemainingTime
        let textColor: NSColor = manager.shouldShowRed ? .systemRed : .labelColor
        let textFont = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)

        let fullTitle = NSMutableAttributedString()

        if !manager.isCompactMode {
            let emoji = manager.nearestEvent()?.event.emoji ?? "🔔"
            fullTitle.append(NSAttributedString(string: emoji, attributes: [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: textColor
            ]))

            fullTitle.append(NSAttributedString(string: " ", attributes: [
                .font: textFont,
                .kern: 2.0
            ]))
        }

        fullTitle.append(NSAttributedString(string: rawText, attributes: [
            .font: textFont,
            .foregroundColor: textColor
        ]))

        button.attributedTitle = fullTitle
        button.image = nil
    }

    @objc private func handleStatusItemClick() {
        let event = NSApp.currentEvent
        
        if event?.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "退出 Zzz", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil // 清除菜单，下次点击依然由 button 响应
        } else {
            togglePopover()
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    deinit {
        timer?.invalidate()
    }
}
