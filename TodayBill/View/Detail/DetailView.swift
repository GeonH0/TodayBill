//
//  DetailView.swift
//  TodayBill
//
//  Created by 김건호 on 2/1/25.
//

import Foundation
import Foundation
import UIKit
import MarqueeLabel

protocol DetailViewDelegate: AnyObject {
    func backButtonTapped()
    func detailLinkButtonTapped(with url: URL)
}

final class DetailView: UIView {
    
    // MARK: - Sticky Header
    private let stickyHeaderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Theme.cellBackgroundColor
        return view
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .black
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.delegate?.backButtonTapped()
        }), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let billNameLabel: MarqueeLabel = {
        let label = MarqueeLabel()
        label.type = .continuous
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.trailingBuffer = 40.0
        label.lineBreakMode = .byClipping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Scrollable Content
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
    
    private let mainStackView: UIStackView = {
       let stack = UIStackView()
       stack.axis = .vertical
       stack.spacing = 24
       stack.translatesAutoresizingMaskIntoConstraints = false
       return stack
    }()
    
    // MARK: - Basic Info Section
    private let basicInfoStack: UIStackView = {
       let stack = UIStackView()
       stack.axis = .vertical
       stack.spacing = 8
       stack.translatesAutoresizingMaskIntoConstraints = false
       return stack
    }()
    
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
    
    // MARK: - Proposal Reason Section
    private let proposalReasonTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "제안 이유"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    
     var proposalReasonExpandableView: ExpandableLabelView = {
        let view = ExpandableLabelView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Key Content Section
    private let keyContentTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "주요 내용"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let keyContentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0  // 여러 줄로 표시
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Timeline Section
    private let timelineTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "진행 단계"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timelineView: TimelineView = {
        let view = TimelineView(steps: [])
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Detail Link Button
    private lazy var detailLinkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("상세페이지 보기", for: .normal)
        button.addAction(UIAction(handler: { [weak self] _ in
            guard let url = self?.detailLinkURL else { return }
            self?.delegate?.detailLinkButtonTapped(with: url)
        }), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var detailLinkURL: URL?
    
    weak var delegate: DetailViewDelegate?
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViewHierarchy()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Setup
    private func setupViewHierarchy() {
        backgroundColor = Theme.backgroundColor
        
        // 1. Sticky Header
        addSubview(stickyHeaderView)
        stickyHeaderView.addSubview(backButton)
        stickyHeaderView.addSubview(billNameLabel)
        
        // 2. Scrollable Content
        addSubview(scrollView)
        scrollView.addSubview(containerView)
        containerView.addSubview(mainStackView)
        
        // Basic Info Section
        basicInfoStack.addArrangedSubview(proposeDateLabel)
        basicInfoStack.addArrangedSubview(ageLabel)
        mainStackView.addArrangedSubview(basicInfoStack)
        
        // Proposal Reason Section
        let proposalReasonStack = UIStackView(arrangedSubviews: [proposalReasonTitleLabel, proposalReasonExpandableView])
        proposalReasonStack.axis = .vertical
        proposalReasonStack.spacing = 8
        proposalReasonStack.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubview(proposalReasonStack)
        
        // Key Content Section
        let keyContentStack = UIStackView(arrangedSubviews: [keyContentTitleLabel, keyContentLabel])
        keyContentStack.axis = .vertical
        keyContentStack.spacing = 8
        keyContentStack.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubview(keyContentStack)
        
        // Timeline Section 추가
        let timelineStack = UIStackView(arrangedSubviews: [timelineTitleLabel, timelineView])
        timelineStack.axis = .vertical
        timelineStack.spacing = 8
        timelineStack.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubview(timelineStack)
        
        // Detail Link Button
        mainStackView.addArrangedSubview(detailLinkButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Sticky Header Constraints
            stickyHeaderView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            stickyHeaderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stickyHeaderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stickyHeaderView.heightAnchor.constraint(equalToConstant: 60),
            
            backButton.leadingAnchor.constraint(equalTo: stickyHeaderView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: stickyHeaderView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 20),
            backButton.heightAnchor.constraint(equalToConstant: 20),
            
            billNameLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            billNameLabel.trailingAnchor.constraint(equalTo: stickyHeaderView.trailingAnchor, constant: -16),
            billNameLabel.centerYAnchor.constraint(equalTo: stickyHeaderView.centerYAnchor),
            
            // Scroll View and Container Constraints
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
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
        ])
    }
    
    // MARK: - Update Method
    /// bill 객체와 함께 HTMLScraper로 추출한 제안 이유, 주요 내용을 받아 업데이트합니다.
    func update(with bill: Row, proposalReason: String, keyContent: String) {
        billNameLabel.text = bill.BILL_NAME
        proposeDateLabel.text = "제안일: \(bill.PROPOSE_DT)"
        ageLabel.text = "대수: \(bill.AGE)"
        
        // 가독성을 위해 라인 스페이싱 적용
        proposalReasonExpandableView.configure(with: proposalReason)
        keyContentLabel.attributedText = makeAttributedText(from: keyContent)
        
        detailLinkURL = URL(string: bill.DETAIL_LINK)
        
        // 타임라인 업데이트 예시 (실제 데이터에 따라 수정 필요)
        let timelineSteps: [TimelineStep] = [
            TimelineStep(title: "제안", date: bill.PROPOSE_DT, isCompleted: true),
            TimelineStep(title: "위원회 처리", date: bill.COMMITTEE_DT ?? "미처리", isCompleted: bill.COMMITTEE_DT != nil),
            TimelineStep(title: "법사위 처리", date: bill.LAW_PROC_DT ?? "미처리", isCompleted: bill.LAW_PROC_DT != nil),
            TimelineStep(title: "본회의 심의", date: bill.PROC_DT ?? "미처리", isCompleted: bill.PROC_DT != nil)
        ]
        
        timelineView.updateSteps(timelineSteps)
    }
    
    private func makeAttributedText(from text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6  // 라인 간격 조정
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.darkText
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }
}
