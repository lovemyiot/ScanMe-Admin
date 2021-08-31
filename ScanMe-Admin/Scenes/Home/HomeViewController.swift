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
    
    private var shouldSaveOnlyOneTag = true
    private var isInSavingMode = false

    var session: NFCTagReaderSession?
    var viewModel: HomeViewModel! {
        didSet {
            viewModel.onTextMessage = { [weak self] vc in
                self?.present(vc, animated: true, completion: nil)
            }
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
        firebaseSignIn()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doneButton.isHidden = true
        readButton.isEnabled = true
        saveButton.isEnabled = true
        viewModel.resetData()
    }
    
    private func firebaseSignIn() {
        Auth.auth().signInAnonymously { [weak self] authResult, error in
            if error != nil {
                self?.showAlert(title: DescriptionKeys.authErrorTitle, message: DescriptionKeys.authError)
            }
        }
    }
    
    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        readButton.layer.cornerRadius = 6
        saveButton.layer.cornerRadius = 6
        activityIndicator.hidesWhenStopped = true
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
        readButton.isEnabled = false
        saveButton.isEnabled = false
        shouldSaveOnlyOneTag = false
        startNFCSession()
    }
    
    private func startNFCSession() {
        session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self)
        session?.alertMessage = DescriptionKeys.sessionAlert
        session?.begin()
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
        viewModel.goToSaveCommand()
    }
}

// MARK: - NFCTagReaderSessionDelegate
extension HomeViewController: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("Session active.")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print("Session ended: \(error.localizedDescription)")
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
            
            switch tag {
            case .miFare(let mifareTag):
                let identifier = mifareTag.identifier.map { String(format: "%.2hhx", $0) }.joined()
                print("MiFare tag detected: \(identifier)")
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
                    session.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        self.startNFCSession()
                    }
                }
                
            default:
                print("Unsupported tag type detected!")
            }
            session.invalidate()
        }
    }
}


