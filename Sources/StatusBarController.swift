import AppKit
import SwiftUI

final class StatusBarController: NSObject {
    private let manager = BedtimeManager.shared
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private var timer: Timer?

    override init() {
        super.init()
        configureStatusItem()
        configurePopover()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refresh()
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
        popover.contentSize = NSSize(width: 280, height: 260)
        popover.contentViewController = NSHostingController(rootView: PopupView())
    }

    func refresh() {
        guard let button = statusItem.button else { return }

        let text = manager.isCompactMode ? manager.formattedRemainingTime : "  \(manager.formattedRemainingTime)"
        let font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        
        if manager.isCompactMode {
            button.image = nil
        } else {
            let image = NSImage(systemSymbolName: "bed.double.badge.checkmark.fill", accessibilityDescription: nil)
            image?.isTemplate = true
            button.image = image
            button.imageScaling = .scaleProportionallyDown
        }
        
        if manager.shouldShowRed {
            // 1. 设置文本颜色
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.systemRed
            ]
            button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
            
            // 2. 设置图标颜色 (手动染色)
            if !manager.isCompactMode, let baseImage = button.image {
                button.image = baseImage.tinted(with: .systemRed)
            }
        } else {
            button.attributedTitle = NSAttributedString(string: "")
            button.title = text
            button.font = font
            if !manager.isCompactMode {
                button.image?.isTemplate = true
            }
            button.contentTintColor = nil
        }
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
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    deinit {
        timer?.invalidate()
    }
}

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        color.set()
        let rect = NSRect(origin: .zero, size: size)
        draw(in: rect, from: rect, operation: .sourceOver, fraction: 1.0)
        rect.fill(using: .sourceAtop)
        newImage.unlockFocus()
        newImage.isTemplate = false
        return newImage
    }
}
