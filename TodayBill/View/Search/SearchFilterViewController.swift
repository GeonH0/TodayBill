import UIKit

/// A single anchored panel. Choices apply immediately without navigating to another menu.
final class SearchFilterViewController: UIViewController, UIPopoverPresentationControllerDelegate, UITextFieldDelegate {
    private(set) var filter: BillFilter
    var onChange: ((BillFilter) -> Void)?
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let committeeField = UITextField()
    private let favoritesSwitch = UISwitch()
    private let resetButton = UIButton(type: .system)
    private var choices: [(UIButton, (BillFilter) -> Bool)] = []

    init(filter: BillFilter) {
        self.filter = filter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.cellBackgroundColor
        view.tintColor = Theme.accent
        scrollView.keyboardDismissMode = .interactive
        stack.axis = .vertical
        stack.spacing = 12
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])

        let title = label("검색 필터", style: .headline)
        resetButton.setTitle("초기화", for: .normal)
        resetButton.accessibilityIdentifier = "filter-reset"
        resetButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        resetButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            // Clear the field before ending editing so an unfinished value cannot restore it.
            self.committeeField.text = nil
            self.filter.resetOptions()
            self.view.endEditing(true)
            self.publish()
        }, for: .touchUpInside)
        stack.addArrangedSubview(row([title, UIView(), resetButton]))

        addSection("진행 상태", rows: [
            row([stage("전체", nil), stage("제안", .proposed), stage("위원회", .committee)]),
            row([stage("법사위", .lawReview), stage("본회의", .plenary), stage("완료", .completed)])
        ])
        addSection("발의 기간", rows: [row([
            choice("전체", selected: { $0.dateRange == .all }) { $0.dateRange = .all },
            choice("최근 30일", selected: { $0.dateRange == .recent(days: 30) }) { $0.dateRange = .recent(days: 30) },
            choice("최근 1년", selected: { $0.dateRange == .recent(days: 365) }) { $0.dateRange = .recent(days: 365) }
        ])])
        addSection("불러온 결과 정렬", rows: [row([
            choice("최신순", selected: { $0.sortOrder == .latest }) { $0.sortOrder = .latest },
            choice("오래된순", selected: { $0.sortOrder == .oldest }) { $0.sortOrder = .oldest }
        ])])
        favoritesSwitch.accessibilityLabel = "관심 법안만"
        favoritesSwitch.accessibilityIdentifier = "filter-favorites"
        favoritesSwitch.onTintColor = Theme.accent
        favoritesSwitch.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.filter.favoriteOnly = self.favoritesSwitch.isOn
            self.publish()
        }, for: .valueChanged)
        let favoritesRow = row([label("관심 법안만", style: .subheadline), UIView(), favoritesSwitch])
        favoritesRow.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        stack.addArrangedSubview(favoritesRow)

        committeeField.placeholder = "위원회명 입력 · 예: 교육"
        committeeField.text = filter.committee
        committeeField.font = .preferredFont(forTextStyle: .subheadline)
        committeeField.adjustsFontForContentSizeCategory = true
        committeeField.textColor = Theme.textColor
        committeeField.borderStyle = .roundedRect
        committeeField.clearButtonMode = .whileEditing
        committeeField.returnKeyType = .done
        committeeField.accessibilityLabel = "소관 위원회, 이름 일부로 검색"
        committeeField.accessibilityIdentifier = "filter-committee"
        committeeField.delegate = self
        committeeField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        addSection("소관 위원회", rows: [committeeField])
        refreshSelection()
    }

    func sizeToFit(width: CGFloat, maximumHeight: CGFloat) {
        let size = stack.systemLayoutSizeFitting(CGSize(width: width - 32, height: 0),
            withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        preferredContentSize = CGSize(width: width, height: min(maximumHeight, size.height + 28))
    }

    private func label(_ text: String, style: UIFont.TextStyle) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: style)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = style == .caption1 ? Theme.textMuted : Theme.textColor
        label.numberOfLines = 0
        return label
    }

    private func row(_ views: [UIView]) -> UIStackView {
        let row = UIStackView(arrangedSubviews: views)
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .center
        if views.allSatisfy({ $0 is UIButton }) { row.distribution = .fillEqually }
        return row
    }

    private func addSection(_ title: String, rows: [UIView]) {
        let section = UIStackView(arrangedSubviews: [label(title, style: .caption1)] + rows)
        section.axis = .vertical
        section.spacing = 4
        stack.addArrangedSubview(section)
    }

    private func stage(_ title: String, _ stage: BillStage?) -> UIButton {
        choice(title, selected: { $0.status == stage }) { $0.status = stage }
    }

    private func choice(_ title: String, selected: @escaping (BillFilter) -> Bool,
                        change: @escaping (inout BillFilter) -> Void) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = title
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4)
        config.background.cornerRadius = 10
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .preferredFont(forTextStyle: .subheadline)
            return attributes
        }
        button.configuration = config
        button.titleLabel?.numberOfLines = 0
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            change(&self.filter)
            self.publish()
        }, for: .touchUpInside)
        choices.append((button, selected))
        return button
    }

    private func refreshSelection() {
        for (button, selected) in choices {
            let isSelected = selected(filter)
            var config = button.configuration
            config?.baseForegroundColor = isSelected ? Theme.textColor : Theme.textSecondary
            config?.background.backgroundColor = isSelected ? Theme.accentSoft : .clear
            config?.background.strokeColor = isSelected ? Theme.accent : Theme.border
            config?.background.strokeWidth = 1
            button.configuration = config
            button.accessibilityTraits = isSelected ? [.button, .selected] : .button
        }
        favoritesSwitch.isOn = filter.favoriteOnly
        resetButton.isEnabled = filter.activeOptionCount > 0
    }

    private func publish() {
        refreshSelection()
        onChange?(filter)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.scrollRectToVisible(textField.convert(textField.bounds, to: scrollView), animated: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let value = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let committee: String? = value.isEmpty ? nil : value
        guard committee != filter.committee else { return }
        filter.committee = committee
        textField.text = committee
        publish()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
        super.viewWillDisappear(animated)
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle { .none }
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle { .none }
}
