//
//  DetailViewController.swift
//  TodayBill
//
//  Created by 김건호 on 2/1/25.
//

import UIKit
import SafariServices

final class DetailViewController: UIViewController {

    private let detailBillService = DetailBillService()
    private let htmlScraper = HTMLScraper()
    private let billID: String
    private let age: Int
    private let contentView = DetailView()
        
    private var currentBill: Row?
    private var isFetching = false
    
    // MARK: - Initializer
    init(billID: String, age: Int) {
        self.billID = billID
        self.age = age
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.cellBackgroundColor
        contentView.delegate = self
        contentView.proposalReasonExpandableView.delegate = self
        fetchBillDetails()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func fetchBillDetails() {
        guard !isFetching else { return }
        isFetching = true
        contentView.showLoading("법안 정보를 불러오는 중입니다.")
        
        detailBillService.fetchBills(ID: billID, age: age) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isFetching = false
                switch result {
                case .success(let rows):
                    if let billDetail = rows.first {
                        self.currentBill = billDetail
                        self.contentView.update(
                            with: billDetail,
                            proposalReason: "요약 정보를 불러오는 중입니다.",
                            keyContent: "요약 정보를 불러오는 중입니다."
                        )
                        self.fetchAndDisplaySummaryContent(url: billDetail.DETAIL_LINK, bill: billDetail)
                    } else {
                        self.contentView.showError("해당 법안 정보를 찾을 수 없습니다.")
                    }
                case .failure:
                    self.contentView.showError("법안 정보를 불러오는 데 실패했습니다.")
                }
            }
        }
    }
    
    private func fetchAndDisplaySummaryContent(url: String, bill: Row) {
        htmlScraper.fetchSummaryContent(from: url) { [weak self] summaryText in
            guard let self = self else { return }
            if let text = summaryText {
                                
                let processedText = text.replacingOccurrences(
                    of: "(?<=\\.)\\s+",
                    with: "\n",
                    options: .regularExpression
                )
                
                // "주요 내용:"을 기준으로 제안 이유와 주요 내용을 분리
                if let range = processedText.range(of: "주요내용") {
                    let proposalReason = String(processedText[..<range.lowerBound])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let keyContent = String(processedText[range.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    DispatchQueue.main.async {
                        self.contentView.update(with: bill, proposalReason: proposalReason, keyContent: keyContent)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.contentView.update(with: bill, proposalReason: processedText, keyContent: "내용 없음")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.contentView.showSummaryUnavailable(for: bill)
                }
            }
        }
    }
    
    private func openSafariViewController(url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .fullScreen
        present(safariVC, animated: true)
    }
    
}

extension DetailViewController: DetailViewDelegate {
    func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    func detailLinkButtonTapped(with url: URL) {
        // 필요 시 SafariViewController 열기
         openSafariViewController(url: url)
    }
    
    func retryButtonTapped() {
        fetchBillDetails()
    }
}

extension DetailViewController: ExpandableLabelViewDelegate {
    func toggleExpanded() {
        contentView.proposalReasonExpandableView.toggleExpanded()
    }
}
