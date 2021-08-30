//
//  SaveCommandViewController.swift
//  ScanMe-Admin
//
//  Created by Jacek Kopaczel on 27/08/2021.
//

import UIKit
import FirebaseFirestore

class SaveCommandViewController: UIViewController {
    @IBOutlet private weak var saveButton: UIButton!
    @IBOutlet private var allTextFields: [UITextField]!
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var firstCommandIdTextField: UITextField!
    @IBOutlet private weak var firstCommandPhoneNumberTextField: UITextField!
    @IBOutlet private weak var firstCommandMessageTextField: UITextField!
    @IBOutlet private weak var firstCommandUrlTextField: UITextField!
    @IBOutlet private weak var firstCommandSsidTextField: UITextField!
    @IBOutlet private weak var firstCommandWifiPasswordTextField: UITextField!
    
    @IBOutlet private weak var secondCommandIdTextField: UITextField!
    @IBOutlet private weak var secondCommandPhoneNumberTextField: UITextField!
    @IBOutlet private weak var secondCommandMessageTextField: UITextField!
    @IBOutlet private weak var secondCommandUrlTextField: UITextField!
    @IBOutlet private weak var secondCommandSsidTextField: UITextField!
    @IBOutlet private weak var secondCommandWifiPasswordTextField: UITextField!
    
    @IBOutlet private weak var conditionTypeTextField: UITextField!
    @IBOutlet private weak var startTimeTextField: UITextField!
    @IBOutlet private weak var endTimeTextField: UITextField!
    @IBOutlet private weak var latitudeTextField: UITextField!
    @IBOutlet private weak var longitudeTextField: UITextField!
    @IBOutlet private weak var radiusTextField: UITextField!
    
    var viewModel: SaveCommandViewModel! {
        didSet {
            viewModel.onPickerViewChoice = { [weak self] type in
                self?.conditionTypeTextField.text = type
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    @objc private func adjustForKeyboard(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height + 20
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset = .zero
        } else {
            scrollView.contentInset = contentInset
        }
    }
    
    private func setupView() {
        saveButton.layer.cornerRadius = 6
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapRecognizer.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapRecognizer)
        allTextFields.forEach {
            $0.delegate = self
            $0.textColor = .black
        }
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 240))
        pickerView.dataSource = viewModel
        pickerView.delegate = viewModel
        conditionTypeTextField.inputView = pickerView
        [firstCommandIdTextField, secondCommandIdTextField, radiusTextField].forEach {
            $0?.keyboardType = .numberPad
        }
        [latitudeTextField, longitudeTextField].forEach {
            $0?.keyboardType = .decimalPad
        }
        scrollView.overrideUserInterfaceStyle = .light
    }
    
    @objc private func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    private func createSaveModel() -> CommandDetailsResponse? {
        var commands: [Command] = []
        guard let firstId = firstCommandIdTextField.text, let safeFirstId = Int(firstId) else { return nil }
        let firstPhoneNumber = firstCommandPhoneNumberTextField.text ?? ""
        let firstMessage = firstCommandMessageTextField.text ?? ""
        let firstUrl = firstCommandUrlTextField.text ?? ""
        let firstSsid = firstCommandSsidTextField.text ?? ""
        let firstWifiPassword = firstCommandWifiPasswordTextField.text ?? ""
        let firstArguments = Arguments(phoneNumber: firstPhoneNumber.isEmpty ? nil : firstPhoneNumber,
                                       message: firstMessage.isEmpty ? nil : firstMessage,
                                       url: firstUrl.isEmpty ? nil : firstUrl,
                                       ssid: firstSsid.isEmpty ? nil : firstSsid,
                                       wifiPassword: firstWifiPassword.isEmpty ? nil : firstWifiPassword)
        let firstCommand = Command(commandId: safeFirstId, arguments: firstArguments)
        commands.append(firstCommand)
        
        if let secondId = secondCommandIdTextField.text, let safeSecondId = Int(secondId) {
            let secondPhoneNumber = secondCommandPhoneNumberTextField.text ?? ""
            let secondMessage = secondCommandMessageTextField.text ?? ""
            let secondUrl = secondCommandUrlTextField.text ?? ""
            let secondSsid = secondCommandSsidTextField.text ?? ""
            let secondWifiPassword = secondCommandWifiPasswordTextField.text ?? ""
            let secondArguments = Arguments(phoneNumber: secondPhoneNumber.isEmpty ? nil : secondPhoneNumber,
                                            message: secondMessage.isEmpty ? nil : secondMessage,
                                            url: secondUrl.isEmpty ? nil : secondUrl,
                                            ssid: secondSsid.isEmpty ? nil : secondSsid,
                                            wifiPassword: secondWifiPassword.isEmpty ? nil : secondWifiPassword)
            let secondCommand = Command(commandId: safeSecondId, arguments: secondArguments)
            commands.append(secondCommand)
        }
        
        var condition: Condition?
        let conditionTypeText = conditionTypeTextField.text ?? ""
        if !conditionTypeText.isEmpty {
            let conditionType: Condition.ConditionType = conditionTypeText == Condition.ConditionType.location.rawValue ? .location: .time
            var coordinates: GeoPoint?
            var radius: Int?
            let startTime = startTimeTextField.text ?? ""
            let endTime = endTimeTextField.text ?? ""
            if let latitude = latitudeTextField.text, let longitude = longitudeTextField.text,
               let latitudeDouble = Double(latitude), let longitudeDouble = Double(longitude) {
                coordinates = GeoPoint(latitude: latitudeDouble, longitude: longitudeDouble)
            }
            if let radiusText = radiusTextField.text, let radiusInt = Int(radiusText) {
                radius = radiusInt
            }
            
            condition = Condition(type: conditionType,
                                  startTime: startTime.isEmpty ? nil : startTime,
                                  endTime: endTime.isEmpty ? nil : endTime,
                                  coordinates: coordinates,
                                  radius: radius)
        }
        
        return CommandDetailsResponse(condition: condition, commands: commands)
    }

    @IBAction func savePressed(_ sender: UIButton) {
        guard let model = createSaveModel() else { return }
        viewModel.saveCommand(model: model) { [weak self] in
            switch $0 {
            case .success():
                self?.showAlert(title: DescriptionKeys.writingSuccessTitle, message: DescriptionKeys.writingSuccess, handler: self?.dismiss)
            case .failure(_):
                self?.showAlert(title: DescriptionKeys.writingErrorTitle, message: DescriptionKeys.writingError, handler: self?.dismiss)
            }
        }
    }
    
    private func dismiss(action: UIAlertAction) {
        viewModel.goBack()
    }
    
    @IBAction func backPressed(_ sender: UIButton) {
        viewModel.goBack()
    }
}

// MARK: - UITextFieldDelegate
extension SaveCommandViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "," {
            textField.text = textField.text! + "."
            return false
        }
        return true
    }
}
