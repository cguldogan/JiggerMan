//
//  PowerInfo.swift
//  JiggerMan
//
//  Created by Can GULDOGAN on 23/12/2025.
//

import Foundation
import IOKit.ps

enum PowerInfo {
    static func batteryPercentage() -> Int? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue()
                    as? [String: Any],
                  let current = description[kIOPSCurrentCapacityKey as String] as? Int,
                  let max = description[kIOPSMaxCapacityKey as String] as? Int,
                  max > 0 else {
                continue
            }
            return Int((Double(current) / Double(max)) * 100.0)
        }
        return nil
    }
}
