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
    func retrySearch()
    func showFilters()
}

final class SearchView: UIView {
    // MARK: - UI Components
    let searchBar: UISearchBar = {
        let searchbar = UISearchBar()
        searchbar.backgroundImage = UIImage()
        searchbar.placeholder = "법안명 또는 키워드 검색"
        searchbar.searchTextField.accessibilityLabel = "법안 검색"
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
        allDeleteButton.accessibilityLabel = "최근 검색어 전체 삭제"
        return allDeleteButton
    }()

    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.bordered()
        config.image = UIImage(systemName: "line.3.horizontal.decrease.circle")
        config.title = "필터"
        config.imagePadding = 6
        config.baseForegroundColor = .systemBlue
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        button.configuration = config
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.delegate?.showFilters()
        }), for: .touchUpInside)
        button.accessibilityLabel = "검색 필터"
        return button
    }()

    private let filterSummaryLabel: UILabel = {
        let label = UILabel()
        label.text = "최신순"
        label.textColor = Theme.emptyLabelTextColor
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let filterStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        return stack
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
        tableView.backgroundColor = Theme.backgroundColor
        return tableView
    }()
    
    private let emptyRecentLabel: UILabel = {
        let label = UILabel()
        label.text = "최근 검색어가 없습니다.\n상단 키워드를 누르거나 법안명을 검색해보세요."
        label.textColor = Theme.emptyLabelTextColor
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    private let statusStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.isHidden = true
        return stack
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.emptyLabelTextColor
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.bordered()
        config.title = "다시 시도"
        config.baseForegroundColor = .systemBlue
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        button.configuration = config
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.delegate?.retrySearch()
        }), for: .touchUpInside)
        return button
    }()
    
    private var recentSearches: [String] = [] {
        didSet {
            recentTableView.reloadData()
            updateEmptyState()
        }
    }
    private var isShowingResults = false
    
    weak var delegate: SearchViewDelegate?

    var resultsTopAnchor: NSLayoutYAxisAnchor {
        filterStackView.bottomAnchor
    }

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

    func updateFilterSummary(_ summary: String) {
        filterSummaryLabel.text = summary
    }

    // MARK: - Private Setup Methods
    private func setupUI() {
        addSubviews()
        setupConstraints()
    }

    private func addSubviews() {
        addSubview(searchBar)
        addSubview(filterStackView)
        addSubview(keywordScrollView)
        addSubview(allDeleteButton)
        addSubview(recentTitleLabel)
        addSubview(recentTableView)
        addSubview(emptyRecentLabel)
        addSubview(statusStackView)
        keywordScrollView.addSubview(keywordStackView)
        keywordScrollView.backgroundColor = Theme.backgroundColor
        statusStackView.addArrangedSubview(loadingIndicator)
        statusStackView.addArrangedSubview(statusLabel)
        statusStackView.addArrangedSubview(retryButton)
        filterStackView.addArrangedSubview(filterButton)
        filterStackView.addArrangedSubview(filterSummaryLabel)
    }

    private func setupConstraints() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        filterStackView.translatesAutoresizingMaskIntoConstraints = false
        keywordScrollView.translatesAutoresizingMaskIntoConstraints = false
        keywordStackView.translatesAutoresizingMaskIntoConstraints = false
        allDeleteButton.translatesAutoresizingMaskIntoConstraints = false
        recentTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        recentTableView.translatesAutoresizingMaskIntoConstraints = false
        emptyRecentLabel.translatesAutoresizingMaskIntoConstraints = false
        statusStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // SearchBar
            searchBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            filterStackView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            filterStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            filterStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            filterStackView.heightAnchor.constraint(equalToConstant: 40),
            
            // Keyword Scroll View
            keywordScrollView.topAnchor.constraint(equalTo: filterStackView.bottomAnchor, constant: 8),
            keywordScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            keywordScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            keywordScrollView.heightAnchor.constraint(equalToConstant: 40),
            
            // Keyword Stack View
            keywordStackView.topAnchor.constraint(equalTo: keywordScrollView.contentLayoutGuide.topAnchor),
            keywordStackView.leadingAnchor.constraint(equalTo: keywordScrollView.contentLayoutGuide.leadingAnchor),
            keywordStackView.trailingAnchor.constraint(equalTo: keywordScrollView.contentLayoutGuide.trailingAnchor),
            keywordStackView.bottomAnchor.constraint(equalTo: keywordScrollView.contentLayoutGuide.bottomAnchor),
            keywordStackView.heightAnchor.constraint(equalTo: keywordScrollView.frameLayoutGuide.heightAnchor),
            
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
            recentTableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            emptyRecentLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            emptyRecentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            emptyRecentLabel.centerYAnchor.constraint(equalTo: recentTableView.centerYAnchor, constant: -40),
            
            statusStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            statusStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            statusStackView.centerYAnchor.constraint(equalTo: recentTableView.centerYAnchor, constant: -40)
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
            button.accessibilityLabel = "\(keyword) 키워드 검색"

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
            keywordStackView.backgroundColor = Theme.backgroundColor
        }
    }

    private func setupTableView() {
        recentTableView.dataSource = self
        recentTableView.delegate = self
        recentTableView.backgroundColor = Theme.backgroundColor
    }
    
    private func updateEmptyState() {
        let isEmpty = recentSearches.isEmpty
        emptyRecentLabel.isHidden = isShowingResults || !isEmpty || !statusStackView.isHidden
        allDeleteButton.isHidden = isShowingResults || isEmpty || !statusStackView.isHidden
    }
    
    func showIdleState() {
        statusStackView.isHidden = true
        loadingIndicator.stopAnimating()
        updateSupplementalContentVisibility()
        updateEmptyState()
    }
    
    func showLoadingState(_ message: String) {
        isShowingResults = false
        statusStackView.isHidden = false
        statusLabel.text = message
        retryButton.isHidden = true
        loadingIndicator.startAnimating()
        keywordScrollView.isHidden = false
        filterStackView.isHidden = false
        recentTitleLabel.isHidden = false
        recentTableView.isHidden = false
        emptyRecentLabel.isHidden = true
        allDeleteButton.isHidden = true
    }
    
    func showErrorState(_ message: String) {
        isShowingResults = false
        statusStackView.isHidden = false
        statusLabel.text = message
        retryButton.isHidden = false
        loadingIndicator.stopAnimating()
        keywordScrollView.isHidden = false
        filterStackView.isHidden = false
        recentTitleLabel.isHidden = false
        recentTableView.isHidden = false
        emptyRecentLabel.isHidden = true
        allDeleteButton.isHidden = true
    }
    
    func setResultsVisible(_ isVisible: Bool) {
        isShowingResults = isVisible
        statusStackView.isHidden = true
        loadingIndicator.stopAnimating()
        updateSupplementalContentVisibility()
        updateEmptyState()
    }
    
    private func updateSupplementalContentVisibility() {
        keywordScrollView.isHidden = isShowingResults
        filterStackView.isHidden = false
        recentTitleLabel.isHidden = isShowingResults
        recentTableView.isHidden = isShowingResults
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
        cell.textLabel?.textColor = Theme.textColor
        cell.backgroundColor = Theme.backgroundColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSearch = recentSearches[indexPath.row]
        delegate?.didSelectSearchTerm(selectedSearch) // Delegate 호출
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
