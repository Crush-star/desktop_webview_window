//
//  WebviewWindowController.swift
//  webview_window
//
//  Created by Bin Yang on 2021/10/15.
//

import Cocoa
import FlutterMacOS
import WebKit

class WebviewWindowController: NSWindowController {
  private let methodChannel: FlutterMethodChannel

  private let viewId: Int64

  private let width, height: Int

  private let titleBarHeight: Int

  private let titleBarTopPadding: Int

  private let title: String

  private let isAlwayOnTop: Bool

  private let windowPosX: Int

  private let windowPosY: Int

  private let showCopyButton:  Bool

  public weak var webviewPlugin: DesktopWebviewWindowPlugin?

  @objc func pinButtonClicked(button: NSButton) {
    window?.level = window?.level == .floating ? .normal : .floating
    button.contentTintColor = window?.level == .floating ?  NSColor.white : NSColor.gray
  }
    
  @objc func copyButtonClicked() {
    methodChannel.invokeMethod("onClickCopy", arguments: ["id": viewId])
  }

    fileprivate func createCopyButton(window: NSWindow) {
        let titleBarView = window.standardWindowButton(.closeButton)!.superview!
        let copyBtn = NSButton()
        copyBtn.setButtonType(.momentaryPushIn)
        // copyBtn.layer?.backgroundColor = NSColor(displayP3Red: 148/255, green: 180/255, blue: 255/255, alpha: 1).cgColor
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor(displayP3Red: 0/255, green: 32/255, blue: 108/255, alpha: 1) //字的颜色
        ]
        let attributedString = NSAttributedString(string: "复制链接", attributes: attributes)
        copyBtn.attributedTitle = attributedString

        if let font = NSFont(name: "Arial", size: 12) {
            copyBtn.font = font
        }
        copyBtn.action = #selector(copyButtonClicked)
        titleBarView.addSubview(copyBtn)
        copyBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            copyBtn.widthAnchor.constraint(equalToConstant: 70.0),
            copyBtn.heightAnchor.constraint(equalToConstant: 22.0),
            copyBtn.trailingAnchor.constraint(equalTo: titleBarView.trailingAnchor, constant: -35),
            copyBtn.topAnchor.constraint(equalTo: titleBarView.topAnchor, constant: 5)
        ])
    }
    
  fileprivate func createToggleFloating(window: NSWindow) {
    let titleBarView = window.standardWindowButton(.closeButton)!.superview!
    
    let btn = NSButton()
    
    btn.setButtonType(.toggle)
    btn.appearance = NSAppearance(named: .darkAqua)
  
    btn.isBordered = false
    btn.action = #selector(pinButtonClicked(button:))
    btn.title = ""
      
    if(isAlwayOnTop){
      btn.contentTintColor = NSColor.white
      window.level = .floating
      btn.image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: nil)
      btn.alternateImage = NSImage(systemSymbolName: "pin.slash.fill", accessibilityDescription: nil)
    }else{          
      btn.image = NSImage(systemSymbolName: "pin.slash.fill", accessibilityDescription: nil)
      btn.alternateImage = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: nil)
    }
    titleBarView.addSubview(btn)
    
    // remember, you ALWAYS need to turn of the auto resize mask!
    btn.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
        btn.widthAnchor.constraint(equalToConstant: 15.0),
        btn.heightAnchor.constraint(equalToConstant: 15.0),
        btn.trailingAnchor.constraint(equalTo: titleBarView.trailingAnchor, constant: -10),
        btn.topAnchor.constraint(equalTo: titleBarView.topAnchor, constant: 8)
    ])
  }

  init(viewId: Int64, methodChannel: FlutterMethodChannel,
       width: Int, height: Int,
       title: String, titleBarHeight: Int,
       isAlwayOnTop: Bool, windowPosX: Int, windowPosY: Int,
       titleBarTopPadding: Int, showCopyButton: Bool
  ) {
    self.viewId = viewId
    self.methodChannel = methodChannel
    self.width = width
    self.height = height
    self.titleBarHeight = titleBarHeight
    self.titleBarTopPadding = titleBarTopPadding
    self.title = title
    self.isAlwayOnTop = isAlwayOnTop
    self.windowPosX = windowPosX
    self.windowPosY = windowPosY
    self.showCopyButton = showCopyButton
    super.init(window: nil)

    let newWindow = NSWindow(contentRect: NSRect(x: windowPosX, y: windowPosY, width: width, height: height), styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
    newWindow.delegate = self
    newWindow.title = title
    newWindow.titlebarAppearsTransparent = true

    createToggleFloating(window: newWindow)
    if (showCopyButton) {
      createCopyButton(window: newWindow)
    }

    let contentViewController = WebViewLayoutController(
      methodChannel: methodChannel,
      viewId: viewId, titleBarHeight: titleBarHeight,
      titleBarTopPadding: titleBarTopPadding)
    newWindow.contentViewController = contentViewController
    newWindow.setContentSize(NSSize(width: width, height: height))
    
    if(windowPosX == 0 && windowPosY == 0){
      newWindow.center()
    }
    
    window = newWindow
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var webViewController: WebViewLayoutController {
    window?.contentViewController as! WebViewLayoutController
  }

  override func keyDown(with event: NSEvent) {
    if event.charactersIgnoringModifiers == "w" && event.modifierFlags.contains(.command) {
      close()
    }
  }

  func destroy() {
    webViewController.destroy()
    webviewPlugin = nil
    window?.delegate = nil
    window = nil
  }

  func setAppearance(brightness: Int) {
    switch brightness {
    case 0:
      if #available(macOS 10.14, *) {
        window?.appearance = NSAppearance(named: .darkAqua)
      } else {
        // Fallback on earlier versions
      }
      break
    case 1:
      window?.appearance = NSAppearance(named: .aqua)
      break
    default:
      window?.appearance = nil
      break
    }
  }

  deinit {
    #if DEBUG
      print("\(self) deinited")
    #endif
  }
}

extension WebviewWindowController: NSWindowDelegate {
  func windowWillClose(_ notification: Notification) {
    webViewController.destroy()
    methodChannel.invokeMethod("onWindowClose", arguments: ["id": viewId])
    webviewPlugin?.onWebviewWindowClose(viewId: viewId, wc: self)
    destroy()
  }
}
