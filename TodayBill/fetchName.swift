import Foundation

extension DetailView {
    
    func fetchRepresentatives() {
        // 1. Load file from the app bundle using relative path
        if let jsonPath = Bundle.main.path(forResource: "name", ofType: "json"),
           let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)) {
            print("Success: \(jsonPath)")
            
            do {
                let representatives = try JSONDecoder().decode([Representative].self, from: jsonData)
                // Process representatives array here
                print(representatives)
            } catch {
                print("Error decoding JSON from app bundle: \(error)")
            }
        } else {
            print("Error reading JSON file from the app bundle.")
        }
        
        // 2. Load file using system path
        let fileManager = FileManager.default
        let systemFilePath = "/private/var/containers/Bundle/Application/1D1B07D9-D05A-4015-9936-D6F108E5926E/TodayBill.app/name.json"
        
        if fileManager.fileExists(atPath: systemFilePath),
           let jsonData = try? Data(contentsOf: URL(fileURLWithPath: systemFilePath)) {
            print("Success: \(systemFilePath)")
            
            do {
                let representatives = try JSONDecoder().decode([Representative].self, from: jsonData)
                // Process representatives array here
                self.name += representatives
                
            } catch {
                print("Error decoding JSON from system path: \(error)")
            }
        } else {
            print("Error reading JSON file from the system path.")
        }
    }
}
