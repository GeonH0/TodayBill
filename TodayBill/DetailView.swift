import UIKit

class DetailView: UIViewController {

    var row: Row
    var name = [Representative]()

    init(row: Row) {
        self.row = row
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        fetchRepresentatives()

        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        let safeAreaTop = view.safeAreaInsets.top

        // 사용자 정의 상단 뷰 생성
        let customTopView = UIView()
        customTopView.backgroundColor = .white
        view.addSubview(customTopView)
        customTopView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customTopView.topAnchor.constraint(equalTo: view.topAnchor),
            customTopView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTopView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTopView.heightAnchor.constraint(equalToConstant: statusBarHeight + safeAreaTop)
        ])

        // 네비게이션 바 생성
        let navBar = UINavigationBar()
        navBar.isTranslucent = false
        navBar.shadowImage = UIImage()

        // 조건에 따라 사용자 정의 상단 뷰 및 네비게이션 바 색상 설정
        for representative in name {
            if row.PROPOSER.contains(representative.HG_NM) {
                setNavigationBarColor(for: representative, customTopView: customTopView, navBar: navBar)
                print(representative.HG_NM, representative.POLY_NM!)
            }
        }

        view.backgroundColor = .white

        // 네비게이션 바의 그림자 제거
        view.addSubview(navBar)
        navBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: customTopView.bottomAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 44)
        ])

        let backButton = UIBarButtonItem(title: "뒤로", style: .plain, target: self, action: #selector(backButtonTapped))

        // UINavigationItem에 백 버튼 추가
        let navItem = UINavigationItem()
        navItem.leftBarButtonItem = backButton
        navBar.setItems([navItem], animated: false)

        let billNameLabel = createLabel(text: "법률안명: \(row.BILL_NAME)", topAnchor: navBar.bottomAnchor, constant: 20)
        billNameLabel.textAlignment = .center
        billNameLabel.font = .boldSystemFont(ofSize: 17)

        let detailPageLabel = createLabel(text: "", topAnchor: billNameLabel.bottomAnchor, constant: 20)
           
           let attributedString = NSMutableAttributedString(string: "상세페이지 : ",
                                                            attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)])
           let linkString = NSAttributedString(string: "바로가기",
                                               attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17),
                                                            NSAttributedString.Key.foregroundColor: UIColor.blue])
           attributedString.append(linkString)
           detailPageLabel.attributedText = attributedString
           
           // 웹 링크를 클릭 가능하도록 설정
           detailPageLabel.isUserInteractionEnabled = true
           let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openDetailLink))
           detailPageLabel.addGestureRecognizer(tapGesture)

        

          // 추가 정보 표시
          let proposeDateLabel = createLabel(text: "제안일: \(row.PROPOSE_DT ?? "정보 없음")", topAnchor: detailPageLabel.bottomAnchor, constant: 20)
          let committeeLabel = createLabel(text: "소관위원회: \(row.COMMITTEE ?? "정보 없음")", topAnchor: proposeDateLabel.bottomAnchor, constant: 20)
          let proposerLabel = createLabel(text: "제안자: \(row.PROPOSER ?? "정보 없음")", topAnchor: committeeLabel.bottomAnchor, constant: 20)
          let lawProcResultLabel = createLabel(text: "법사위처리결과: \(row.LAW_PROC_RESULT_CD ?? "정보 없음")", topAnchor: proposerLabel.bottomAnchor, constant: 20)
          let procResultLabel = createLabel(text: "본회의심의결과: \(row.PROC_RESULT ?? "정보 없음")", topAnchor: lawProcResultLabel.bottomAnchor, constant: 20)
    }

    func setNavigationBarColor(for representative: Representative, customTopView: UIView, navBar: UINavigationBar) {
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

    func createLabel(text: String, topAnchor: NSLayoutYAxisAnchor, constant: CGFloat) -> UILabel {
        let label = UILabel()
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: constant),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
        return label
    }

    @objc func backButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func openDetailLink() {
        if let url = URL(string: row.DETAIL_LINK), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
