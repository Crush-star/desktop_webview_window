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

  public weak var webviewPlugin: DesktopWebviewWindowPlugin?

  @objc func pinButtonClicked(button: NSButton) {
    window?.level = window?.level == .floating ? .normal : .floating
    button.contentTintColor = window?.level == .floating ?  NSColor.white : NSColor.gray
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
        btn.topAnchor.constraint(equalTo: titleBarView.topAnchor, constant: 7)
    ])
  }

  init(viewId: Int64, methodChannel: FlutterMethodChannel,
       width: Int, height: Int,
       title: String, titleBarHeight: Int,
       isAlwayOnTop: Bool,
       titleBarTopPadding: Int) {
    self.viewId = viewId
    self.methodChannel = methodChannel
    self.width = width
    self.height = height
    self.titleBarHeight = titleBarHeight
    self.titleBarTopPadding = titleBarTopPadding
    self.title = title
    self.isAlwayOnTop = isAlwayOnTop
    super.init(window: nil)

    let newWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: height), styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
    newWindow.delegate = self
    newWindow.title = title
    newWindow.titlebarAppearsTransparent = true

    createToggleFloating(window: newWindow)

    let contentViewController = WebViewLayoutController(
      methodChannel: methodChannel,
      viewId: viewId, titleBarHeight: titleBarHeight,
      titleBarTopPadding: titleBarTopPadding)
    newWindow.contentViewController = contentViewController
    newWindow.setContentSize(NSSize(width: width, height: height))
    newWindow.center()

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
