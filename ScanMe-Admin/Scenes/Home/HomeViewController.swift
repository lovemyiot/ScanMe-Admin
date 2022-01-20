//
//  HomeViewController.swift
//  ScanMe - NFC reader
//
//  Created by Jacek Kopaczel on 30/03/2021.
//

import UIKit
import CoreNFC
import FirebaseAuth

class HomeViewController: UIViewController {
    @IBOutlet private weak var readButton: UIButton!
    @IBOutlet private weak var saveButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var doneButton: UIButton!
    @IBOutlet private weak var scannedTagsLabel: UILabel!
    @IBOutlet private weak var loginButton: UIButton!
    @IBOutlet private weak var helloLabel: UILabel!
    @IBOutlet private weak var signOutButton: UIButton!
    
    private var shouldSaveOnlyOneTag = true
    private var isInSavingMode = false
    private var isLoggedIn: Bool = false {
        didSet {
            readButton.isEnabled = isLoggedIn
            saveButton.isEnabled = isLoggedIn
            readButton.backgroundColor = isLoggedIn ? .white : Colors.lightGray
            saveButton.backgroundColor = isLoggedIn ? .white : Colors.lightGray
            loginButton.isHidden = isLoggedIn
            helloLabel.isHidden = !isLoggedIn
            signOutButton.isHidden = !isLoggedIn
        }
    }
    
    var handle: AuthStateDidChangeListenerHandle?
    
    private var username: String?

    var session: NFCTagReaderSession?
    var viewModel: HomeViewModel! {
        didSet {
            viewModel.onAlert = { [weak self] title, message in
                self?.showAlert(title: title, message: message)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkNFCAvailability()
        setupView()
        CommandManager.shared.locationManager.requestWhenInUseAuthorization()
        handle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            guard let user = user else {
                self.username = nil
                self.isLoggedIn = false
                return
            }
            self.isLoggedIn = true
            let username = user.displayName ?? user.email
            self.helloLabel.text = "Hello \n\(username ?? "")"
            self.username = username
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doneButton.isHidden = true
        readButton.isEnabled = isLoggedIn
        saveButton.isEnabled = isLoggedIn
        scannedTagsLabel.isHidden = true
        viewModel.resetData()
    }
    
    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        readButton.layer.cornerRadius = 6
        saveButton.layer.cornerRadius = 6
        loginButton.layer.cornerRadius = 6
        signOutButton.layer.cornerRadius = 6
        activityIndicator.hidesWhenStopped = true
        readButton.setTitleColor(.systemGray, for: .disabled)
        saveButton.setTitleColor(.systemGray, for: .disabled)
    }
    
    private func checkNFCAvailability() {
        if !NFCTagReaderSession.readingAvailable {
            readButton.isEnabled = false
            showAlert(title: DescriptionKeys.scanningNotSupportedTitle, message: DescriptionKeys.scanningNotSupported)
        }
    }
    
    private func saveOne(action: UIAlertAction) {
        shouldSaveOnlyOneTag = true
        startNFCSession()
    }
    
    private func saveMore(action: UIAlertAction) {
        doneButton.isHidden = false
        scannedTagsLabel.isHidden = false
        shouldSaveOnlyOneTag = false
        startNFCSession()
    }
    
    private func startNFCSession() {
        session = NFCTagReaderSession(pollingOption: [.iso14443, .iso18092, .iso15693], delegate: self)
        session?.alertMessage = DescriptionKeys.sessionAlert
        session?.begin()
    }
    
    private func showLoginPopup() {
        let alertController = UIAlertController(title: DescriptionKeys.authenticationRequired, message: "", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = DescriptionKeys.username
        }
        alertController.addTextField { textField in
            textField.placeholder = DescriptionKeys.password
            textField.isSecureTextEntry = true
        }
        let loginAction = UIAlertAction(title: "Sign in", style: .default, handler: { [weak self] _ in
            let username = alertController.textFields![0].text ?? ""
            let password = alertController.textFields![1].text ?? ""
            self?.signIn(username, password)
        })
        
        alertController.addAction(loginAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alertController, animated: true, completion: nil)
    }
    
    private func signIn(_ username: String, _ password: String) {
        Auth.auth().signIn(withEmail: username, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            guard error == nil else {
                self.showAlert(title: DescriptionKeys.authErrorTitle, message: DescriptionKeys.authError)
                return
            }
            self.isLoggedIn = true
        }
    }
    
    private func proceedWithTag(_ identifier: String) {
        if !self.isInSavingMode {
            DispatchQueue.main.async {
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.viewModel.fetchCommand(for: identifier) { [weak self] commandDetails in
                    self?.viewModel.processCommand(commandDetails) { [weak self] in
                        DispatchQueue.main.async {
                            self?.activityIndicator.stopAnimating()
                        }
                    }
                }
            }
        } else if self.shouldSaveOnlyOneTag {
            self.viewModel.identifiers.append(identifier)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.viewModel.goToSaveCommand()
            }
        } else {
            self.viewModel.identifiers.append(identifier)
            session?.invalidate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.startNFCSession()
            }
        }
    }
    
    @IBAction func readPressed(_ sender: UIButton) {
        isInSavingMode = false
        viewModel.resetData()
        startNFCSession()
    }
    
    @IBAction func savePressed(_ sender: UIButton) {
        isInSavingMode = true
        let alertController = UIAlertController(
            title: DescriptionKeys.numberOfTags,
            message: DescriptionKeys.saveOneOrMore,
            preferredStyle: .alert
                )
        alertController.addAction(UIAlertAction(title: "One", style: .default, handler: saveOne))
        alertController.addAction(UIAlertAction(title: "More", style: .default, handler: saveMore))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func donePressed(_ sender: UIButton) {
        scannedTagsLabel.isHidden = true
        viewModel.resetData()
        viewModel.goToSaveCommand()
    }
    
    @IBAction func loginPressed(_ sender: UIButton) {
        showLoginPopup()
    }
    
    @IBAction func signOutPressed(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            showAlert(title: DescriptionKeys.signOutErrorTitle, message: DescriptionKeys.signOutError)
        }
    }
}

// MARK: - NFCTagReaderSessionDelegate
extension HomeViewController: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("Session active.")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print("Session ended: \(error.localizedDescription)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if (error as? NFCReaderError)?.errorCode == NFCReaderError.readerSessionInvalidationErrorSessionTimeout.rawValue {
                self.scannedTagsLabel.isHidden = !(self.viewModel.identifiers.count > 0)
            }
            self.doneButton.isHidden = !(self.viewModel.identifiers.count > 0)
            self.scannedTagsLabel.text = "Scanned tags: \(self.viewModel.identifiers.count)"
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }
        if tags.count > 1 {
            session.alertMessage = DescriptionKeys.tooManyTags
            session.invalidate()
        }
        session.connect(to: tag) { error in
            if error != nil {
                session.invalidate(errorMessage: DescriptionKeys.connectionFailed)
            }
            var identifier: String
            switch tag {
            case .miFare(let tag):
                identifier = tag.identifier.map { String(format: "%.2hhx", $0) }.joined()
                print("MiFare tag detected: \(identifier)")
            case .iso7816(let tag):
                identifier = tag.identifier.map { String(format: "%.2hhx", $0) }.joined()
                print("ISO7816 tag detected: \(identifier)")
            case .iso15693(let tag):
                identifier = tag.identifier.map { String(format: "%.2hhx", $0) }.joined()
                print("ISO15693 tag detected: \(identifier)")
            case .feliCa(let tag):
                identifier = tag.currentIDm.map { String(format: "%.2hhx", $0) }.joined()
                print("FeliCa tag detected: \(identifier)")
            default:
                identifier = ""
                print("Unsupported tag type detected!")
            }
            if identifier != "" {
                self.proceedWithTag(identifier)
            }
            session.invalidate()
        }
    }
}
