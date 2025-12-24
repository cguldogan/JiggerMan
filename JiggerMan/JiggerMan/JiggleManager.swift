//
//  JiggleManager.swift
//  JiggerMan
//
//  Created by Can GULDOGAN on 23/12/2025.
//

import Combine
import CoreGraphics
import Foundation

final class JiggleManager: ObservableObject {
    @Published var isJiggling = false {
        didSet {
            if isJiggling {
                startJiggle()
            } else {
                stopJiggle()
            }
        }
    }
    
    var distance: Double = 50.0

    private var timer: Timer?

    private func startJiggle() {
        print("JiggleManager: Starting jiggle timer")
        stopJiggle() // Ensure no duplicate timers
        // Jiggle immediately
        performJiggle()
        // Then every 60 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.performJiggle()
        }
    }

    private func stopJiggle() {
        print("JiggleManager: Stopping jiggle timer")
        timer?.invalidate()
        timer = nil
    }

    private func performJiggle() {
        print("JiggleManager: Attempting to perform jiggle")
        guard let currentPos = CGEvent(source: nil)?.location else {
            print("JiggleManager: Failed to get current mouse location")
            return
        }
        print("JiggleManager: Current mouse location: \(currentPos)")
        
        // Move pixels right to make it visible
        let offset: CGFloat = CGFloat(distance)
        let newPos = CGPoint(x: currentPos.x + offset, y: currentPos.y)
        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: newPos, mouseButton: .left)
        moveEvent?.post(tap: .cghidEventTap)
        print("JiggleManager: Posted move event to \(newPos)")
        
        // Move back after a short delay to make it visible to the human eye
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let backPos = CGPoint(x: currentPos.x, y: currentPos.y)
            let backEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: backPos, mouseButton: .left)
            backEvent?.post(tap: .cghidEventTap)
            print("JiggleManager: Posted back event to \(backPos)")
        }

        LogStore.shared.append(LogEntry(action: "Simulated Activity", reason: "Mouse Jiggle"))
    }
}
