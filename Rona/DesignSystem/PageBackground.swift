//
//  PageBackground.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 04/11/26.
//

import SwiftUI

// The background behind every full-screen page.
struct PageBackground: View {
    var body: some View {
        LinearGradient(colors: [Theme.leaf, Theme.sunlight], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

#Preview {
    PageBackground()
}
