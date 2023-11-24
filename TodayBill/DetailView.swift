import Foundation
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
        customTopView.backgroundColor = .white // 기본 색상
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
                    view.backgroundColor = .white
                }
                print(representative.HG_NM, representative.POLY_NM!)
            }
        }

        view.backgroundColor = .white
        super.viewDidLoad()

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
    }

    @objc func backButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}
