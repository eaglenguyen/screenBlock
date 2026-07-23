//
//  CompactActivityDisplay.swift
//  Runner
//
//  Created by Egor on 7/16/26.
//

import SwiftUI
import DeviceActivity

struct CompactActivityDisplay: View {
    let configuration: ActivityConfiguration

    private var isDark: Bool {
        UserDefaults(suiteName: "group.com.eagle.pausenow")?.bool(forKey: "appIsDarkMode") ?? true
    }

    var body: some View {
        Text(configuration.formattedTotal)
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(isDark ? .white : Color(red: 0x17/255, green: 0x17/255, blue: 0x1A/255))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isDark ? Color(red: 0x25/255, green: 0x25/255, blue: 0x25/255) : Color.white)
    }
}
