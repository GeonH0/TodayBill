import UIKit

class DetailView: UIView {
    
    private var row: Row
    private var name = [Representative]()
    
    private let customTopView = UIView()
    private let navBar = UINavigationBar()
    
    init(row: Row, name: [Representative]) {
        self.row = row
        self.name = name
        super.init(frame: .zero)
        setupView()
        setupNavigationBar()
        setupLabels()
        setupGestureRecognizers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .white
        addSubview(customTopView)
        addSubview(navBar)
        
        customTopView.backgroundColor = .white
        customTopView.translatesAutoresizingMaskIntoConstraints = false
        navBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            customTopView.topAnchor.constraint(equalTo: topAnchor),
            customTopView.leadingAnchor.constraint(equalTo: leadingAnchor),
            customTopView.trailingAnchor.constraint(equalTo: trailingAnchor),
            customTopView.heightAnchor.constraint(equalToConstant: UIApplication.shared.statusBarFrame.height + safeAreaInsets.top),
            
            navBar.topAnchor.constraint(equalTo: customTopView.bottomAnchor),
            navBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        for representative in name {
            if row.PROPOSER.contains(representative.HG_NM) {
                setNavigationBarColor(for: representative)
            }
        }
        
        let backButton = UIBarButtonItem(title: "뒤로", style: .plain, target: self, action: #selector(backButtonTapped))
        let navItem = UINavigationItem()
        navItem.leftBarButtonItem = backButton
        navBar.setItems([navItem], animated: false)
    }
    
    private func setupNavigationBar() {
        navBar.isTranslucent = false
        navBar.shadowImage = UIImage()
    }
    
    private func setupLabels() {
        let billNameLabel = createLabel(text: "법률안명: \(row.BILL_NAME)", topAnchor: navBar.bottomAnchor, constant: 20)
        billNameLabel.textAlignment = .center
        billNameLabel.font = .boldSystemFont(ofSize: 17)
        
        let detailPageLabel = createLabel(text: "", topAnchor: billNameLabel.bottomAnchor, constant: 20)
        let attributedString = NSMutableAttributedString(string: "상세페이지 : ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)])
        let linkString = NSAttributedString(string: "바로가기", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.blue])
        attributedString.append(linkString)
        detailPageLabel.attributedText = attributedString
        
        let proposerLabel = createLabel(text: "제안자: \(row.PROPOSER ?? "정보 없음")", topAnchor: detailPageLabel.bottomAnchor, constant: 20)
        let lawProcDateLabel = createLabel(text: "법사위처리일: \(row.LAW_PROC_DT ?? "정보 없음")", topAnchor: proposerLabel.bottomAnchor, constant: 20)
        let lawPresentDateLabel = createLabel(text: "법사위상정일: \(row.LAW_PRESENT_DT ?? "정보 없음")", topAnchor: lawProcDateLabel.bottomAnchor, constant: 20)
        let lawSubmitDateLabel = createLabel(text: "법사위회부일: \(row.LAW_SUBMIT_DT ?? "정보 없음")", topAnchor: lawPresentDateLabel.bottomAnchor, constant: 20)
        let cmtProcResultLabel = createLabel(text: "소관위처리결과: \(row.CMT_PROC_RESULT_CD ?? "정보 없음")", topAnchor: lawSubmitDateLabel.bottomAnchor, constant: 20)
        let lawProcResultLabel = createLabel(text: "법사위처리결과: \(row.LAW_PROC_RESULT_CD ?? "정보 없음")", topAnchor: cmtProcResultLabel.bottomAnchor, constant: 20)
        let proposeDateLabel = createLabel(text: "제안일: \(row.PROPOSE_DT ?? "정보 없음")", topAnchor: lawProcResultLabel.bottomAnchor, constant: 20)
        let committeeLabel = createLabel(text: "소관위원회: \(row.COMMITTEE ?? "정보 없음")", topAnchor: proposeDateLabel.bottomAnchor, constant: 20)
        let procResultLabel = createLabel(text: "본회의심의결과: \(row.PROC_RESULT ?? "정보 없음")", topAnchor: committeeLabel.bottomAnchor, constant: 20)
    }
    
    private func setupGestureRecognizers() {
        let detailPageLabel = createLabel(text: "", topAnchor: navBar.bottomAnchor, constant: 20)
        detailPageLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openDetailLink))
        detailPageLabel.addGestureRecognizer(tapGesture)
    }
    
    private func setNavigationBarColor(for representative: Representative) {
        switch representative.POLY_NM {
        case "더불어민주당":
            navBar.barTintColor = .blue
            customTopView.backgroundColor = .blue
        case "국민의힘":
            navBar.barTintColor = .red
            customTopView.backgroundColor = .red
        case "정의당":
            navBar.barTintColor = .yellow
            customTopView.backgroundColor = .yellow
        default:
            break
        }
    }
    
    private func createLabel(text: String, topAnchor: NSLayoutYAxisAnchor, constant: CGFloat) -> UILabel {
        let label = UILabel()
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: constant),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
        ])
        return label
    }
    
    @objc private func backButtonTapped() {
        if let viewController = self.parentViewController as? DetailViewController {
            viewController.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func openDetailLink() {
        if let url = URL(string: row.DETAIL_LINK), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while let nextResponder = parentResponder?.next {
            parentResponder = nextResponder
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
