import UIKit

/// Owns the filter form layout; draft values and application stay in the controller.
final class SearchFilterView: UIView {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    let resetButton = UIButton(type: .system)
    let applyButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.backgroundColor
        tableView.backgroundColor = Theme.backgroundColor
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 52
        tableView.accessibilityIdentifier = "search-filter-options"
        resetButton.setTitle("초기화", for: .normal)
        resetButton.accessibilityIdentifier = "search-filter-reset"
        resetButton.tintColor = Theme.textSecondary
        var config = UIButton.Configuration.filled()
        config.title = "적용"
        config.baseBackgroundColor = Theme.accent
        config.baseForegroundColor = Theme.onAccent
        config.background.cornerRadius = Theme.Radius.button
        applyButton.configuration = config
        applyButton.accessibilityIdentifier = "search-filter-apply"
        let actions = UIStackView(arrangedSubviews: [resetButton, applyButton])
        actions.spacing = 16
        actions.distribution = .fillEqually
        actions.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tableView)
        addSubview(actions)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: actions.topAnchor, constant: -8),
            actions.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            actions.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            actions.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor, constant: -12),
            resetButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            applyButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Edits a value copy. Only Apply publishes the draft; cancel/swipe-to-dismiss discard it.
final class SearchFilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    private let contentView = SearchFilterView()
    private let committeeField = UITextField()
    private(set) var draft: BillFilter
    var onApply: ((BillFilter) -> Void)?
    private let statuses: [BillStage?] = [nil, .proposed, .committee, .lawReview, .plenary, .completed]
    private let periods: [(String, BillDateRange)]
    private let sorts: [BillSortOrder] = [.latest, .oldest]
    private var didApply = false

    init(filter: BillFilter) {
        draft = filter
        var values: [(String, BillDateRange)] = [("전체 기간", .all), ("최근 30일", .recent(days: 30)), ("최근 1년", .recent(days: 365))]
        if !values.contains(where: { $0.1 == filter.dateRange }) { values.append((filter.dateRange.title, filter.dateRange)) }
        periods = values
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func loadView() { view = contentView }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "검색 필터"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "취소", style: .plain, target: self, action: #selector(cancel))
        navigationController?.navigationBar.tintColor = Theme.accent
        contentView.tableView.dataSource = self
        contentView.tableView.delegate = self
        committeeField.text = draft.committee
        committeeField.placeholder = "위원회명 입력 (예: 교육)"
        committeeField.accessibilityLabel = "소관 위원회"
        committeeField.accessibilityIdentifier = "search-filter-committee"
        committeeField.clearButtonMode = .whileEditing
        committeeField.font = .preferredFont(forTextStyle: .body)
        committeeField.adjustsFontForContentSizeCategory = true
        committeeField.textColor = Theme.textColor
        committeeField.returnKeyType = .done
        committeeField.delegate = self
        committeeField.addTarget(self, action: #selector(committeeChanged), for: .editingChanged)
        contentView.resetButton.addTarget(self, action: #selector(resetDraft), for: .touchUpInside)
        contentView.applyButton.addTarget(self, action: #selector(applyDraft), for: .touchUpInside)
    }

    @objc private func cancel() { dismiss(animated: true) }
    @objc private func committeeChanged() {
        let value = committeeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        draft.committee = value.isEmpty ? nil : value
    }
    @objc func resetDraft() {
        draft.resetOptions()
        committeeField.text = nil
        contentView.tableView.reloadData()
    }
    @objc func applyDraft() {
        guard !didApply else { return }
        committeeChanged()
        view.endEditing(true)
        didApply = true
        onApply?(draft)
        dismiss(animated: true)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { textField.resignFirstResponder(); return true }
    func numberOfSections(in tableView: UITableView) -> Int { 5 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section { case 0: return statuses.count; case 3: return periods.count; case 4: return sorts.count; default: return 1 }
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        ["진행 상태", "소관 위원회", "관심 법안", "발의 기간", "불러온 결과 정렬"][section]
    }
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 { return "입력한 이름을 포함하는 위원회로 검색합니다. 비우면 전체 위원회입니다." }
        if section == 4 { return "정렬은 현재까지 불러온 법안에 적용됩니다. 추가 결과를 불러오면 순서가 바뀔 수 있습니다." }
        return nil
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = Theme.cellBackgroundColor
        cell.tintColor = Theme.accent
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.textColor = Theme.textColor
        cell.textLabel?.numberOfLines = 0
        var selected = false
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = statuses[indexPath.row]?.title ?? "전체 상태"
            selected = draft.status == statuses[indexPath.row]
        case 1:
            cell.selectionStyle = .none
            committeeField.removeFromSuperview()
            committeeField.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(committeeField)
            NSLayoutConstraint.activate([
                committeeField.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                committeeField.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                committeeField.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
                committeeField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),
                committeeField.heightAnchor.constraint(greaterThanOrEqualToConstant: 32)
            ])
        case 2: cell.textLabel?.text = "관심 법안만 보기"; selected = draft.favoriteOnly
        case 3: cell.textLabel?.text = periods[indexPath.row].0; selected = draft.dateRange == periods[indexPath.row].1
        default: cell.textLabel?.text = sorts[indexPath.row].title; selected = draft.sortOrder == sorts[indexPath.row]
        }
        cell.accessoryType = selected ? .checkmark : .none
        if selected { cell.accessibilityTraits.insert(.selected) }
        cell.accessibilityIdentifier = "search-filter-option-\(indexPath.section)-\(indexPath.row)"
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0: draft.status = statuses[indexPath.row]
        case 1: committeeField.becomeFirstResponder(); return
        case 2: draft.favoriteOnly.toggle()
        case 3: draft.dateRange = periods[indexPath.row].1
        default: draft.sortOrder = sorts[indexPath.row]
        }
        tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
    }
}
