//
//  AnalysisCalendarFilterModel.swift
//  Baraka
//
//  Created by Abdul Wahab on 23/09/2022.
//  Copyright © 2022 Baraka LTD. All rights reserved.
//

import Foundation

struct CalendarRangeModel {
    let selectedMin: Date?
    let selectedMax: Date?
    let minDate: Date?
    let maxDate: Date?
    let delegate: CalendarRangeDelegate
}
