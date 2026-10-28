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
        searchbar.searchBarStyle = .minimal
        searchbar.backgroundColor = Theme.backgroundColor
        searchbar.barTintColor = Theme.backgroundColor
        searchbar.isTranslucent = false
        searchbar.backgroundImage = UIImage()
        searchbar.placeholder = "법안명 또는 키워드 검색"
        searchbar.searchTextField.accessibilityLabel = "법안 검색"
        searchbar.searchTextField.backgroundColor = Theme.cellBackgroundColor
        searchbar.searchTextField.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        searchbar.searchTextField.textColor = Theme.textColor
        searchbar.searchTextField.layer.cornerRadius = Theme.Radius.field
        searchbar.searchTextField.layer.masksToBounds = true
        searchbar.searchTextField.clipsToBounds = true
        searchbar.tintColor = Theme.accent
        searchbar.setImage(
            UIImage(
                systemName: "magnifyingglass",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
            )?.withTintColor(Theme.textMuted, renderingMode: .alwaysOriginal),
            for: .search,
            state: .normal
        )
        return searchbar
    }()
    
    private lazy var allDeleteButton: UIButton = {
        let allDeleteButton = UIButton()
        let attributedText = NSAttributedString(
            string: "전체 삭제",
            attributes: [
                .font: Theme.Font.metaStrong,
                .foregroundColor: Theme.textMuted
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
        var config = UIButton.Configuration.plain()
        config.image = UIImage(
            systemName: "chevron.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        )
        config.title = "최신순"
        config.imagePlacement = .trailing
        config.imagePadding = 5
        config.baseForegroundColor = Theme.textMuted
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.Font.metaStrong
            return outgoing
        }
        button.configuration = config
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.delegate?.showFilters()
        }), for: .touchUpInside)
        button.accessibilityLabel = "검색 필터"
        return button
    }()

    private let resultTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "검색 결과"
        label.font = UIFont.systemFont(ofSize: 14, weight: .heavy)
        label.textColor = Theme.textColor
        label.isHidden = true
        return label
    }()

    private let resultCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .heavy)
        label.textColor = Theme.accent
        label.isHidden = true
        return label
    }()

    private let filterStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        return stack
    }()
    
    private let keywordScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
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
        label.text = "최근 검색"
        label.font = Theme.Font.sectionHeading
        label.textColor = Theme.textColor
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
        label.font = Theme.Font.statusMessage
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
        label.font = Theme.Font.statusMessage
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = "다시 시도"
        config.baseForegroundColor = Theme.accent
        config.background.backgroundColor = Theme.accentSoft
        config.background.cornerRadius = Theme.Radius.chip
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.Font.chip
            return outgoing
        }
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
        filterButton.configuration?.title = summary
    }

    /// Shows "검색 결과 24" beside the sort chip; `nil` hides the pair while idle.
    func updateResultCount(_ count: Int?) {
        resultTitleLabel.isHidden = count == nil
        resultCountLabel.isHidden = count == nil
        resultCountLabel.text = count.map { "\($0)" }
    }

    // MARK: - Private Setup Methods
    private func setupUI() {
        backgroundColor = Theme.backgroundColor
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
        filterStackView.addArrangedSubview(resultTitleLabel)
        filterStackView.addArrangedSubview(resultCountLabel)
        filterStackView.addArrangedSubview(UIView())
        filterStackView.addArrangedSubview(filterButton)
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
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            filterStackView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            filterStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.Spacing.screenHorizontal),
            filterStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.Spacing.screenHorizontal),
            filterStackView.heightAnchor.constraint(equalToConstant: 40),
            
            // Keyword Scroll View
            keywordScrollView.topAnchor.constraint(equalTo: filterStackView.bottomAnchor, constant: 8),
            keywordScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.Spacing.screenHorizontal),
            keywordScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.Spacing.screenHorizontal),
            keywordScrollView.heightAnchor.constraint(equalToConstant: 40),
            
            // Keyword Stack View
            keywordStackView.topAnchor.constraint(equalTo: keywordScrollView.contentLayoutGuide.topAnchor),
            keywordStackView.leadingAnchor.constraint(equalTo: keywordScrollView.contentLayoutGuide.leadingAnchor),
            keywordStackView.trailingAnchor.constraint(equalTo: keywordScrollView.contentLayoutGuide.trailingAnchor),
            keywordStackView.bottomAnchor.constraint(equalTo: keywordScrollView.contentLayoutGuide.bottomAnchor),
            keywordStackView.heightAnchor.constraint(equalTo: keywordScrollView.frameLayoutGuide.heightAnchor),
            
            // All Delete Button
            allDeleteButton.topAnchor.constraint(equalTo: keywordScrollView.bottomAnchor, constant: 16),
            allDeleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.Spacing.screenHorizontal),
            
            // Recent Title Label
            recentTitleLabel.topAnchor.constraint(equalTo: keywordScrollView.bottomAnchor, constant: 16),
            recentTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.Spacing.screenHorizontal),
            
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
            // 칩: 흰 면 + 11 라운드. 구분은 그림자가 아니라 배경과의 명도 차로 만든다.
            var config = UIButton.Configuration.plain()
            config.title = keyword
            config.background.backgroundColor = Theme.cellBackgroundColor
            config.background.cornerRadius = Theme.Radius.chip
            config.baseForegroundColor = Theme.textSecondary
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 13, bottom: 8, trailing: 13)
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = Theme.Font.chip
                return outgoing
            }
            button.configuration = config
            button.accessibilityLabel = "\(keyword) 키워드 검색"

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
        cell.textLabel?.font = Theme.Font.rowValue
        cell.textLabel?.textColor = Theme.textSecondary
        cell.backgroundColor = Theme.backgroundColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSearch = recentSearches[indexPath.row]
        delegate?.didSelectSearchTerm(selectedSearch) // Delegate 호출
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
