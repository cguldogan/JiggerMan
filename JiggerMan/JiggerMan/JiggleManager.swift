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
            guard oldValue != isJiggling else { return }
            if isJiggling {
                startJiggle()
            } else {
                stopJiggle()
            }
        }
    }
    
    var distance: Double = 50.0
    var interval: Double = 5.0

    /// True while a programmatic jiggle move is in-flight (used to distinguish from real user movement).
    private(set) var isPerformingJiggle = false

    private var timer: Timer?

    private func startJiggle() {
        print("JiggleManager: Starting jiggle timer")
        stopJiggle() // Ensure no duplicate timers
        // Jiggle immediately
        performJiggle()
        // Then every interval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
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
        
        isPerformingJiggle = true

        // Move pixels right to make it visible
        let offset: CGFloat = CGFloat(distance)
        let newPos = CGPoint(x: currentPos.x + offset, y: currentPos.y)
        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: newPos, mouseButton: .left)
        moveEvent?.post(tap: .cghidEventTap)
        print("JiggleManager: Posted move event to \(newPos)")
        
        // Move back after a short delay to make it visible to the human eye
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            let backPos = CGPoint(x: currentPos.x, y: currentPos.y)
            let backEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: backPos, mouseButton: .left)
            backEvent?.post(tap: .cghidEventTap)
            print("JiggleManager: Posted back event to \(backPos)")
            // Allow a small grace period for the posted event to propagate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.isPerformingJiggle = false
            }
        }
    }
}
