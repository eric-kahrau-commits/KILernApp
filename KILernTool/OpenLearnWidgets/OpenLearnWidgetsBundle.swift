//
//  OpenLearnWidgetsBundle.swift
//  OpenLearnWidgets
//
//  Created by Eric on 17.03.26.
//

import WidgetKit
import SwiftUI

@main
struct OpenLearnWidgetsBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        TodayWidget()
        QuickStatsWidget()
    }
}
