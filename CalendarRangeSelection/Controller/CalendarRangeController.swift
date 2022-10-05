//
//  PortfolioAnalysisCalendarController.swift
//  Baraka
//
//  Created by Abdul Wahab on 19/09/2022.
//  Copyright © 2022 Baraka LTD. All rights reserved.
//

import Foundation
import UIKit
import FSCalendar
import RxRelay
import RxSwift
import RxCocoa
import ControlKit

final class CalendarRangeController: UIViewController {
    
    private unowned var calendar: FSCalendar!
    private unowned var closeButton: UIButton!
    private unowned var titleLabel: UILabel!
    private unowned var periodLabel: UILabel!
    private unowned var applyButton: Button!
    
    private var minDate: Date?
    private var maxDate: Date?
    
    private let vm: CalendarRangeViewModel
    private let bag: DisposeBag
    
    private var dateSelected = BehaviorRelay<Date?>(value: nil)
    
    init(viewModel: CalendarRangeViewModel) {
        self.vm = viewModel
        self.bag = DisposeBag()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("not available")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindViewModel()
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        view.isOpaque = false
        
        let container = UIStackView().also {
            $0.axis = .vertical
            $0.distribution = .fill
            $0.alignment = .leading
            $0.spacing = Resource.Dim.sm
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
            NSLayoutConstraint.activate([
                $0.topAnchor.constraint(equalTo: view.topAnchor, constant: Resource.Dim.md),
                $0.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Resource.Dim.md),
                $0.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Resource.Dim.md)
            ])
        }
        
        closeButton = UIButton().also {
            $0.setImage(Images.Generic.close.image, for: .normal)
            container.addArrangedSubview($0)
        }
        
        titleLabel = UILabel().also {
            $0.font = .H4.semiBold
            $0.textColor = .Content.normal
            $0.text = L10n.Portfolio.Analysis.History.period
            
            container.addArrangedSubview($0)
        }
        
        periodLabel = UILabel().also {
            $0.font = .Body.regular
            $0.textColor = .Content.opacity50
            
            container.addArrangedSubview($0)
        }
        
        calendar = FSCalendar().also {
            $0.backgroundColor = .clear
            $0.dataSource = self
            $0.delegate = self
            
            $0.scrollEnabled = true
            $0.scrollDirection = .vertical
            $0.allowsMultipleSelection = true
            $0.pagingEnabled = false
            
            $0.appearance.also {
                $0.todayColor = .clear
                $0.selectionColor = .Solid.green
                $0.weekdayTextColor = .Content.opacity50
                $0.titleDefaultColor = .Content.normal
                $0.titleTodayColor = .Content.normal
                $0.headerTitleColor = .Content.normal
                $0.headerSeparatorColor = .clear
                
                $0.titleFont = .H5.semiBold
                $0.headerTitleFont = .H5.semiBold
            }
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
            
            NSLayoutConstraint.activate([
                $0.topAnchor.constraint(equalTo: container.bottomAnchor, constant: Resource.Dim.sm),
                $0.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Resource.Dim.xxxl),
                $0.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Resource.Dim.sm),
                $0.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Resource.Dim.sm)
            ])
        }
        
        applyButton = Button(configuration: Button.Configuration.contained()).also {
            $0.isHidden = true
            $0.text = L10n.Portfolio.Analysis.History.applyDates
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
            
            NSLayoutConstraint.activate([
                $0.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                $0.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Resource.Dim.xxxl)
            ])
        }
    }
    
    private func bindViewModel() {
        let dateSelected = dateSelected
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
        
        let input = CalendarRangeViewModel.Input(
            dateSelected: dateSelected,
            apply: applyButton.rx.tap.asDriver(),
            dismiss: closeButton.rx.tap.asDriver()
        )
        
        let output = vm.transform(input: input)
        
        let disposables = [
            output.range.drive(periodLabel.rx.text),
            output.selectedDates.drive(dateSelectionBinder),
            output.dismiss.drive(dismissBinder),
            output.hideApply.drive(applyButton.rx.isHidden),
            output.minDate.drive(minDateBinder),
            output.maxDate.drive(maxDateBinder)
        ]

        disposables.forEach { $0.disposed(by: bag) }
    }
    
    private var minDateBinder: Binder<Date> {
        return Binder(self) { host, date in
            host.minDate = date
            host.calendar.reloadData()
        }
    }
    
    private var maxDateBinder: Binder<Date> {
        return Binder(self) { host, date in
            host.maxDate = date
            host.calendar.reloadData()
        }
    }
    
    private var dateSelectionBinder: Binder<[Date]> {
        return Binder(calendar) { calendar, dates in
            if dates.count == 2,
               var start = dates.first,
               let end = dates.last {

                while start.compare(end) != .orderedDescending {
                    calendar.select(start)
                    start = start.byAdding(value: 1, for: .day)
                }
            } else {
                calendar.selectedDates.forEach {
                    calendar.deselect($0)
                }
                if dates.count == 1 {
                    calendar.select(dates.first)
                }
            }
        }
    }
    
    private var dismissBinder: Binder<()> {
        return Binder(self) { host, _ in
            host.dismiss(animated: true)
        }
    }
}

extension CalendarRangeController: FSCalendarDataSource, FSCalendarDelegate {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        dateSelected.accept(date.toLocalDateTime())
    }
    
    func calendar(_ calendar: FSCalendar, didDeselect date: Date, at monthPosition: FSCalendarMonthPosition) {
        dateSelected.accept(date.toLocalDateTime())
    }
    
    func minimumDate(for calendar: FSCalendar) -> Date {
        return minDate ?? calendar.minimumDate
    }
    
    func maximumDate(for calendar: FSCalendar) -> Date {
        return maxDate ?? calendar.maximumDate
    }
}
