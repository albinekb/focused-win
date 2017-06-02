//
//  main.swift
//  focused-win
//
//  Created by Albin Ekblom on 2017-06-02.
//  Copyright © 2017 Albin Ekblom. All rights reserved.
//

import Foundation
import AppKit

extension String {
  /// Encode a String to Base64
  func toBase64() -> String {
    return Data(self.utf8).base64EncodedString()
  }
  
  /// Decode a String from Base64. Returns nil if unsuccessful.
  func fromBase64() -> String? {
    guard let data = Data(base64Encoded: self) else { return nil }
    return String(data: data, encoding: .utf8)
  }
}

func toJson<T>(_ data: T) throws -> String {
  let json = try JSONSerialization.data(withJSONObject: data)
  return String(data: json, encoding: .utf8)!
}

func getPid (win: [String: AnyObject]) -> pid_t {
  return win["kCGWindowOwnerPID"] as! pid_t
}

func getWindowList () -> [[String: AnyObject]] {
  let options: CGWindowListOption = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
  let cfInfoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
  let infoList = cfInfoList! as? [[String: AnyObject]] ?? []

  return infoList
}

func getBounds (win: [String: AnyObject]) -> [String: Int] {
  if let bounds = win["kCGWindowBounds"] {
    return [
      "x": bounds["X"] as? Int ?? 0,
      "y": bounds["Y"] as? Int ?? 0,
      "height": bounds["Height"] as? Int ?? 0,
      "width": bounds["Width"] as? Int ?? 0,
    ]
  }
  
  return [:]
}


func main () throws -> String {
  let workspace = NSWorkspace.shared()
  let focusedApp = workspace.frontmostApplication
//  let menubarApp = workspace.menuBarOwningApplication
  
  for win in getWindowList() {
    let winPid = getPid(win: win)
    if winPid == focusedApp?.processIdentifier {
        let bounds = getBounds(win: win)
        let jsonObject: [String: Any] = [
          "bounds": bounds,
          "app": (win["kCGWindowOwnerName"] as? String ?? "").toBase64(),
          "title": (win["kCGWindowName"] as? String ?? "").toBase64(),
          "pid": winPid
        ]
      
      if bounds["height"]! <= 1 || bounds["width"]! <= 1 {
        continue
      }
        let json = try toJson(jsonObject)
        return json
        //break
    }
  }
  
  return ""
}


var cached = ""
let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
    do {
      setbuf(stdout, nil)
      let json = try main()
      if json == cached {
        return
      } else {
        cached = json
        print(json)
      }
    } catch {
      exit(1)
    }
}

RunLoop.main.run()
//setbuf(__stdoutp, nil)
