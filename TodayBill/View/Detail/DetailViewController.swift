//
//  DetailViewController.swift
//  TodayBill
//
//  Created by 김건호 on 2/1/25.
//

import UIKit
import SafariServices

final class DetailViewController: UIViewController {

    private let billID: String
    private let age: Int
    private let contentView = DetailView()
    private lazy var viewModel = DetailViewModel(billID: billID, age: age)
        
    private var currentSnapshot: BillSnapshot?
    
    // MARK: - Initializer
    init(billID: String, age: Int) {
        self.billID = billID
        self.age = age
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
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
        bindViewModel()
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
        viewModel.load()
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self = self else { return }

            switch state {
            case .idle:
                break
            case .loading(let message):
                self.contentView.showLoading(message)
            case .loaded(let snapshot):
                self.currentSnapshot = snapshot
                self.render(snapshot: snapshot)
            case .empty(let message), .error(let message):
                self.contentView.showError(message)
            }
        }

        viewModel.onSummaryUpdate = { [weak self] snapshot in
            self?.currentSnapshot = snapshot
            self?.render(snapshot: snapshot)
        }
    }

    private func render(snapshot: BillSnapshot) {
        contentView.update(
            with: snapshot,
            proposalReason: snapshot.summaryProposalReason,
            keyContent: snapshot.summaryKeyContent
        )
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

    func favoriteButtonTapped() {
        viewModel.toggleFavorite()
    }
    
    func detailLinkButtonTapped(with url: URL) {
        openSafariViewController(url: url)
    }
    
    func retryButtonTapped() {
        viewModel.retry()
    }
}

extension DetailViewController: ExpandableLabelViewDelegate {
    func toggleExpanded() {
        contentView.proposalReasonExpandableView.toggleExpanded()
    }
}
