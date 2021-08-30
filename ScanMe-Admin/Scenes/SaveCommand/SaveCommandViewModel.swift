//
//  SaveCommandViewModel.swift
//  ScanMe-Admin
//
//  Created by Jacek Kopaczel on 27/08/2021.
//

import XCoordinator

class SaveCommandViewModel: NSObject {
    private let router: UnownedRouter<MainRoute>
    private var pickerSource: [Condition.ConditionType.RawValue] = []
    let identifiers: [String]
    
    var onPickerViewChoice: ((String) -> Void)?
    
    init(router: UnownedRouter<MainRoute>, identifiers: [String]) {
        self.router = router
        self.identifiers = identifiers
        super.init()
        Condition.ConditionType.allCases.forEach {
            pickerSource.append($0.rawValue)
        }
    }
    
    func goBack() {
        router.trigger(.back)
    }
    
    func saveCommand(model: CommandDetailsResponse, completion: @escaping (Result<Void, Error>) -> Void) {
        let group = DispatchGroup()
        for identifier in identifiers {
            group.enter()
            DataManager.shared.addCommand(command: model, for: identifier, in: FirestoreKeys.tagsCollection) {
                switch $0 {
                case .success():
                    print("Successfully wrote to Firestore!")
                    completion(.success(()))
                case .failure(let error):
                    print("Error writing to Firestore: \(error)")
                    completion(.failure(error))
                }
                group.leave()
            }
        }
        group.wait()
    }
}

// MARK: - UIPickerViewDataSource
extension SaveCommandViewModel: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerSource.count
    }
}

extension SaveCommandViewModel: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        pickerSource[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        onPickerViewChoice?(pickerSource[row])
    }
}
