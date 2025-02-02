//
//  DetailView.swift
//  TodayBill
//
//  Created by 김건호 on 2/1/25.
//

import Foundation
import UIKit

protocol DetailViewDelegate: AnyObject {
    func backButtonTapped()
    func detailLinkButtonTapped(with url: URL)    
}

final class DetailView: UIView {
    
    // MARK: - Sticky Header (법안 제목만 고정)
    private let stickyHeaderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .black
        button.addAction(
            UIAction(
                handler: { [weak self] _ in
                    self?.delegate?.backButtonTapped()
                }
            ),
            for: .touchUpInside
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let billNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byClipping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - ScrollView & Container (나머지 컨텐츠 영역)
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Main StackView (스크롤되는 컨텐츠)
    private let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - 기타 섹션 UI 요소 (고정 헤더 제외)
    private let proposeDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let ageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 처리 정보 섹션
    private let procResultLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let procDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Timeline 섹션
    private let timelineView: TimelineView = {
        let view = TimelineView(steps: [])
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // 위원회 정보 섹션
    private let committeeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let committeeIdLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let committeeProcessDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 법사위 정보 섹션
    private let lawProcDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let lawPresentDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let lawSubmitDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var detailLinkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("상세페이지", for: .normal)
        button.addAction(
            UIAction(
                handler: { [weak self] _ in
                    guard let url = self?.detailLinkURL else { return }
                    self?.delegate?.detailLinkButtonTapped(with: url)
                }
            ),
            for: .touchUpInside
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
//    private lazy var memberListButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("제안자목록", for: .normal)
//        button.addAction(
//            UIAction(
//                handler: { [weak self] _ in
//                    guard let url = self?.memberListURL else { return }
//                    self?.delegate?.memberListButtonTapped(with: url)
//                }
//            ),
//            for: .touchUpInside
//        )
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
    
    //MARK: - 추후 MarqueeLabel 도입 예정
    private let publProposerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var detailLinkURL: URL?
    private var memberListURL: URL?
    weak var delegate: DetailViewDelegate?
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViewHierarchy()
        setupConstraints()
        configureSections()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Setup
    private func setupViewHierarchy() {
        backgroundColor = .white
        
        // 1. Sticky Header 추가 (법안 제목만)
        addSubview(stickyHeaderView)
        stickyHeaderView.addSubview(backButton)
        stickyHeaderView.addSubview(billNameLabel)
        
        
        // 2. 스크롤 영역 추가 (나머지 컨텐츠)
        addSubview(scrollView)
        scrollView.addSubview(containerView)
        containerView.addSubview(mainStackView)
        
        let basicStack = UIStackView(arrangedSubviews: [proposeDateLabel, ageLabel])
        basicStack.axis = .vertical
        basicStack.spacing = 8
        
        
        let processingStack = UIStackView(arrangedSubviews: [procResultLabel, procDateLabel])
        processingStack.axis = .vertical
        processingStack.spacing = 8
        
        
        let committeeStack = UIStackView(arrangedSubviews: [committeeLabel, committeeIdLabel, committeeProcessDateLabel])
        committeeStack.axis = .vertical
        committeeStack.spacing = 8
        
        
        let lawCommitteeStack = UIStackView(arrangedSubviews: [lawProcDateLabel, lawPresentDateLabel, lawSubmitDateLabel])
        lawCommitteeStack.axis = .vertical
        lawCommitteeStack.spacing = 8
        
        
        let additionalStack = UIStackView(arrangedSubviews: [detailLinkButton, publProposerLabel])
        additionalStack.axis = .vertical
        additionalStack.spacing = 8
        
        
        mainStackView.addArrangedSubview(basicStack)
        mainStackView.addArrangedSubview(processingStack)
        mainStackView.addArrangedSubview(timelineView)
        mainStackView.addArrangedSubview(committeeStack)
        mainStackView.addArrangedSubview(lawCommitteeStack)
        mainStackView.addArrangedSubview(additionalStack)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            stickyHeaderView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            stickyHeaderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stickyHeaderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stickyHeaderView.heightAnchor.constraint(equalToConstant: 60),
            
            
            backButton.leadingAnchor.constraint(equalTo: stickyHeaderView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: stickyHeaderView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 20),
            backButton.heightAnchor.constraint(equalToConstant: 20),
            
            // MARK: MarqueeLabel 도입 예정
            billNameLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            billNameLabel.trailingAnchor.constraint(equalTo: stickyHeaderView.trailingAnchor, constant: -16),
            billNameLabel.centerYAnchor.constraint(equalTo: stickyHeaderView.centerYAnchor),
            
            scrollView.topAnchor.constraint(equalTo: stickyHeaderView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -55),
            
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    private func configureSections() {
        proposeDateLabel.text = "제안일: "
        ageLabel.text = "대수: "
        
        procResultLabel.text = "본회의심의결과: "
        procDateLabel.text = "의결일: "
        
        committeeLabel.text = "소관위원회: "
        committeeIdLabel.text = "소관위원회ID: "
        committeeProcessDateLabel.text = "소관위원회 처리일: "
        
        lawProcDateLabel.text = "법사위처리일: "
        lawPresentDateLabel.text = "법사위상정일: "
        lawSubmitDateLabel.text = "법사위회부일: "
        
        publProposerLabel.text = "공동발의자: "
    }
    
    // MARK: - Update Method
    func update(with bill: Row) {
        committeeIdLabel.text = bill.BILL_ID
        
        billNameLabel.text = bill.BILL_NAME
        
        proposeDateLabel.text = "제안일: \(bill.PROPOSE_DT)"
        ageLabel.text = "대수: \(bill.AGE)"
        
        procResultLabel.text = "본회의심의결과: \(bill.PROC_RESULT ?? "정보 없음")"
        procDateLabel.text = "의결일: \(bill.PROC_DT ?? "정보 없음")"
        
        committeeLabel.text = "소관위원회: \(bill.COMMITTEE ?? "정보 없음")"
        committeeIdLabel.text = "소관위원회ID: \(bill.COMMITTEE_ID ?? "정보 없음")"
        committeeProcessDateLabel.text = "소관위원회 처리일: \(bill.COMMITTEE_DT ?? "정보 없음")"
        
        lawProcDateLabel.text = "법사위처리일: \(bill.LAW_PROC_DT ?? "정보 없음")"
        lawPresentDateLabel.text = "법사위상정일: \(bill.LAW_PRESENT_DT ?? "정보 없음")"
        lawSubmitDateLabel.text = "법사위회부일: \(bill.LAW_SUBMIT_DT ?? "정보 없음")"
        
        detailLinkURL = URL(string: bill.DETAIL_LINK)
        publProposerLabel.text = "공동발의자: \(bill.PUBL_PROPOSER ?? "정보 없음")"
        
        let timelineSteps: [TimelineStep] = [
            TimelineStep(title: "제안", date: bill.PROPOSE_DT, isCompleted: true),
            TimelineStep(title: "위원회 처리", date: bill.COMMITTEE_DT ?? "미처리", isCompleted: bill.COMMITTEE_DT != nil),
            TimelineStep(title: "법사위 처리", date: bill.LAW_PROC_DT ?? "미처리", isCompleted: bill.LAW_PROC_DT != nil),
            TimelineStep(title: "본회의 심의", date: bill.PROC_DT ?? "미처리", isCompleted: bill.PROC_DT != nil)
        ]
        
        timelineView.updateSteps(timelineSteps)
    }
}
