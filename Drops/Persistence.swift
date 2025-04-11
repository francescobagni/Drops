import Foundation
import SwiftUI

class Persistence: ObservableObject {
    static let shared = Persistence()
    private let regionsKey = "storedRegions"
    private let contrastMapKey = "storedContrastMap"
    private let intensityMapKey = "storedIntensityMap"

    private init() {}
    
    // MARK: - Store Data
    func storeRegions(_ regions: [UIImage]) {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: regions, requiringSecureCoding: false) else { return }
        UserDefaults.standard.set(data, forKey: regionsKey)
    }
    
    func storeContrastMap(_ map: UIImage) {
        guard let data = map.pngData() else { return }
        UserDefaults.standard.set(data, forKey: contrastMapKey)
    }
    
    func storeIntensityMap(_ map: UIImage) {
        guard let data = map.pngData() else { return }
        UserDefaults.standard.set(data, forKey: intensityMapKey)
    }
    
    // MARK: - Retrieve Data
    func retrieveRegions() -> [UIImage]? {
        guard let data = UserDefaults.standard.data(forKey: regionsKey),
              let regions = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [UIImage] else {
            return nil
        }
        return regions
    }
    
    func retrieveContrastMap() -> UIImage? {
        guard let data = UserDefaults.standard.data(forKey: contrastMapKey) else { return nil }
        return UIImage(data: data)
    }
    
    func retrieveIntensityMap() -> UIImage? {
        guard let data = UserDefaults.standard.data(forKey: intensityMapKey) else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - Clear Stored Data (When New Image is Selected)
    func clearStoredData() {
        UserDefaults.standard.removeObject(forKey: regionsKey)
        UserDefaults.standard.removeObject(forKey: contrastMapKey)
        UserDefaults.standard.removeObject(forKey: intensityMapKey)
    }
}
