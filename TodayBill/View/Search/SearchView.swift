//
//  SearchView.swift
//  TodayBill
//
//  Created by 김건호 on 1/23/25.
//

import UIKit


protocol SearchViewDelegate: AnyObject {
    func deleteAll()
    func didSelectSearchTerm(_ term: String) // 검색어 선택
}

final class SearchView: UIView {
    // MARK: - UI Components
    let searchBar: UISearchBar = {
        let searchbar = UISearchBar()
        searchbar.backgroundImage = UIImage()
        return searchbar
    }()
    
    private lazy var allDeleteButton: UIButton = {
        let allDeleteButton = UIButton()
        let attributedText = NSAttributedString(
            string: "전체 삭제",
            attributes: [
                .font: UIFont.systemFont(ofSize: 15),
                .foregroundColor: UIColor.black,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        allDeleteButton.setAttributedTitle(attributedText, for: .normal)
        allDeleteButton.addAction(
            UIAction(handler: { [weak self] _ in
                self?.delegate?.deleteAll()
            }),
            for: .touchUpInside
        )
        return allDeleteButton
    }()
    
    private let keywordScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .white
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private let keywordStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()
    
    private let recentTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "최근검색"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        return label
    }()
    
    private let recentTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchCell")
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private var recentSearches: [String] = [] {
        didSet {
            recentTableView.reloadData()
        }
    }
    
    weak var delegate: SearchViewDelegate?

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupKeywords()
        setupTableView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let keywords = ["부동산","안전","근로","산업","환경","교육"]
    
    // MARK: - Public Methods
    func updateRecentSearches(_ searches: [String]) {
        self.recentSearches = searches
    }

    // MARK: - Private Setup Methods
    private func setupUI() {
        addSubviews()
        setupConstraints()
    }

    private func addSubviews() {
        addSubview(searchBar)
        addSubview(keywordScrollView)
        addSubview(allDeleteButton)
        addSubview(recentTitleLabel)
        addSubview(recentTableView)
        keywordScrollView.addSubview(keywordStackView)
    }

    private func setupConstraints() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        keywordScrollView.translatesAutoresizingMaskIntoConstraints = false
        keywordStackView.translatesAutoresizingMaskIntoConstraints = false
        allDeleteButton.translatesAutoresizingMaskIntoConstraints = false
        recentTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        recentTableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // SearchBar
            searchBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            // Keyword Scroll View
            keywordScrollView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            keywordScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            keywordScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            keywordScrollView.heightAnchor.constraint(equalToConstant: 40),
            
            // Keyword Stack View
            keywordStackView.topAnchor.constraint(equalTo: keywordScrollView.topAnchor),
            keywordStackView.leadingAnchor.constraint(equalTo: keywordScrollView.leadingAnchor),
            keywordStackView.trailingAnchor.constraint(equalTo: keywordScrollView.trailingAnchor),
            keywordStackView.bottomAnchor.constraint(equalTo: keywordScrollView.bottomAnchor),
            
            // All Delete Button
            allDeleteButton.topAnchor.constraint(equalTo: keywordScrollView.bottomAnchor, constant: 16),
            allDeleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // Recent Title Label
            recentTitleLabel.topAnchor.constraint(equalTo: keywordScrollView.bottomAnchor, constant: 16),
            recentTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            // Recent Table View
            recentTableView.topAnchor.constraint(equalTo: recentTitleLabel.bottomAnchor, constant: 8),
            recentTableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            recentTableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            recentTableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupKeywords() {
        keywords.forEach { keyword in
            let button = UIButton()

            // 버튼 스타일 설정
            var config = UIButton.Configuration.plain()
            config.title = keyword
            config.baseBackgroundColor = .white
            config.baseForegroundColor = UIColor.black // 텍스트 색상 검정
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20) // 내부 여백
            button.configuration = config
            button.titleLabel?.font = .systemFont(ofSize: 14)

            button.layer.cornerRadius = 8
            button.layer.masksToBounds = false
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGray5.cgColor

            // 그림자 효과
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.15
            button.layer.shadowOffset = CGSize(width: 0, height: 8)
            button.layer.shadowRadius = 12

            // 버튼 클릭 이벤트 추가 (UIAction 사용)
            let action = UIAction { [weak self] _ in
                self?.delegate?.didSelectSearchTerm(keyword)
            }
            button.addAction(action, for: .touchUpInside)

            keywordStackView.addArrangedSubview(button)
        }
    }

    private func setupTableView() {
        recentTableView.dataSource = self
        recentTableView.delegate = self
    }
}

// MARK: - UITableView DataSource & Delegate
extension SearchView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentSearches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath)
        cell.textLabel?.text = recentSearches[indexPath.row]
        cell.textLabel?.font = .systemFont(ofSize: 14)
        cell.textLabel?.textColor = .darkGray
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSearch = recentSearches[indexPath.row]
        delegate?.didSelectSearchTerm(selectedSearch) // Delegate 호출
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
