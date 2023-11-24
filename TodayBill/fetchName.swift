import Foundation

extension DetailView {
    
    func fetchRepresentatives() {
        // 1. Load file from the app bundle
        if let jsonPath = Bundle.main.path(forResource: "name", ofType: "json"),
           let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)) {

            
            do {
                let representatives = try JSONDecoder().decode([Representative].self, from: jsonData)
                // Process representatives array here
                self.name += representatives
            } catch {
                print("Error decoding JSON from app bundle: \(error)")
            }
        } else {
            print("Error reading JSON file from the app bundle.")
        }
    }
}
