import Foundation
import UIKit

class DetailViewController: UIViewController {
    
    private var row: Row
    private var name = [Representative]()
    
    init(row: Row) {
        self.row = row
        super.init(nibName: nil, bundle: nil)
        fetchRepresentatives()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = DetailView(row: row, name: name)
    }
    
    private func fetchRepresentatives() {
        if let jsonPath = Bundle.main.path(forResource: "name", ofType: "json"),
           let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)) {
            do {
                let representatives = try JSONDecoder().decode([Representative].self, from: jsonData)
                self.name += representatives
            } catch {
                print("Error decoding JSON from app bundle: \(error)")
            }
        } else {
            print("Error reading JSON file from the app bundle.")
        }
    }
}
