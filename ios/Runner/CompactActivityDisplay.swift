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

    var body: some View {
        Text(configuration.formattedTotal)
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity) // 👈 new — fill the whole slot
            .background(Color(red: 0x25/255, green: 0x25/255, blue: 0x25/255)) // 👈 new — opaque, covers whatever's beneath
    }
}
