//
//  PortfolioAnalysisCalendarViewModel.swift
//  Baraka
//
//  Created by Abdul Wahab on 19/09/2022.
//  Copyright © 2022 Baraka LTD. All rights reserved.
//

import RxSwift
import RxCocoa
import UIKit
import FSCalendar

final class CalendarRangeViewModel: ViewModel {
    
    private var disposeBag: DisposeBag
    private var delegate: CalendarRangeDelegate
    private let minDate: Date?
    private let maxDate: Date?
    let selectedRange: BehaviorRelay<[Date]>
    
    init(model: CalendarRangeModel) {
        self.disposeBag = DisposeBag()
        self.delegate = model.delegate
        self.minDate = model.minDate
        self.maxDate = model.maxDate
        if let selectedMax = model.selectedMax,
           let selectedMin = model.selectedMin {
            selectedRange = BehaviorRelay<[Date]>(value: [selectedMin,selectedMax])
        } else {
            selectedRange = BehaviorRelay<[Date]>(value: [])
        }
    }
    
    struct Input {
        let dateSelected: Driver<Date>
        let apply: Driver<()>
        let dismiss: Driver<()>
    }
    
    struct Output {
        let range: Driver<String>
        let selectedDates: Driver<[Date]>
        let dismiss: Driver<()>
        let hideApply: Driver<Bool>
        let minDate: Driver<Date>
        let maxDate: Driver<Date>
    }
    
    func transform(input: Input) -> Output {
        let selectedDates = input.dateSelected
            .asObservable()
            .withLatestFrom(selectedRange.asObservable()) { [weak self] date, range -> [Date] in
                switch range.count {
                case 0, 2:
                    let startDate = Calendar.current.startOfDay(for: date)
                    self?.selectedRange.accept([startDate])
                    return [startDate]
                case 1:
                    if let previousDate = range.first {
                        let endDate = Calendar.current.startOfDay(for: date)
                        if endDate >= previousDate {
                            let completeRange = [previousDate, endDate]
                            self?.selectedRange.accept(completeRange)
                            return completeRange
                        } else {
                            return [previousDate]
                        }
                    }
                default:
                    break
                }
                return []
            }
            .startWith(selectedRange.value)
            .compactMap{ $0 }
            .asDriver(onErrorDriveWith: .empty())
        
        let range = selectedDates
            .map { range -> String in
                if range.count == 2 {
                    if let first = range.first?.toPickerDate(),
                       let last = range.last?.toPickerDate() {
                        return "\(first) - \(last)"
                    } else {
                        return ""
                    }
                } else {
                    return ""
                }
            }
            .asDriver(onErrorDriveWith: .empty())
        
        let apply = input.apply
            .do(onNext: { [weak self] in
                let start = self?.selectedRange.value.first
                var end = self?.selectedRange.value.last
                end = end?.byAdding(value: 1, for: .day)
                self?.delegate.dateRangeSelected(start: start,
                                                 end: end)
            })
                
        let dismiss = Driver.merge(
            apply,
            input.dismiss
        )
                
        let hideApply = selectedDates
        .map { return $0.count != 2 }
        
        let minDate = Observable.just(minDate)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
        
        let maxDate = Observable.just(maxDate)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
        
        return Output(
            range: range,
            selectedDates: selectedDates,
            dismiss: dismiss,
            hideApply: hideApply,
            minDate: minDate,
            maxDate: maxDate
        )
    }
}


