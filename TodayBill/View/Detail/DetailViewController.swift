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
    private let billID: String
    private let age: Int
    private let contentView = DetailView()
    
    
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
        view.backgroundColor = .white
        contentView.delegate = self
        fetchBillDetails()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func fetchBillDetails() {
        detailBillService.fetchBills(ID: billID, age: age) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let rows):
                    if let billDetail = rows.first {
                        self.updateUI(with: billDetail)
                    } else {
                        self.showError("해당 법안 정보를 찾을 수 없습니다.")
                    }
                case .failure:
                    self.showError("법안 정보를 불러오는 데 실패했습니다.")
                }
            }
        }
    }
    
    private func updateUI(with bill: Row) {        
        contentView.update(with: bill)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "검색 실패", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func openSafariViewController(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .fullScreen
        present(safariViewController, animated: true)
    }
}

extension DetailViewController: DetailViewDelegate {
    func backButtonTapped() {        
        self.navigationController?.popViewController(animated: true)
    }
    
    func detailLinkButtonTapped(with url: URL) {        
        openSafariViewController(url: url)
    }
}
