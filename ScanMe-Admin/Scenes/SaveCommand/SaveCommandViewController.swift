//
//  SaveCommandViewController.swift
//  ScanMe-Admin
//
//  Created by jacek.kopaczel on 27/08/2021.
//

import UIKit

class SaveCommandViewController: UIViewController {
    @IBOutlet private weak var saveButton: UIButton!
    @IBOutlet private weak var firstCommandId: UITextField!
    @IBOutlet private weak var firstCommandPhoneNumber: UITextField!
    @IBOutlet private weak var firstCommandMessage: UITextField!
    @IBOutlet private weak var firstCommandUrl: UITextField!
    @IBOutlet private weak var firstCommandSsid: UITextField!
    @IBOutlet private weak var firstCommandWifiPassword: UITextField!
    
    @IBOutlet private weak var secondCommandId: UITextField!
    @IBOutlet private weak var secondCommandPhoneNumber: UITextField!
    @IBOutlet private weak var secondCommandMessage: UITextField!
    @IBOutlet private weak var secondCommandUrl: UITextField!
    @IBOutlet private weak var secondCommandSsid: UITextField!
    @IBOutlet private weak var secondCommandWifiPassword: UITextField!
    
    @IBOutlet private weak var conditionType: UITextField!
    @IBOutlet private weak var startTime: UITextField!
    @IBOutlet private weak var endTime: UITextField!
    @IBOutlet private weak var coordinates: UITextField!
    @IBOutlet private weak var radius: UITextField!
    
    
    
    var viewModel: SaveCommandViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        saveButton.layer.cornerRadius = 6
        firstCommandId.attributedPlaceholder
    }

    @IBAction func savePressed(_ sender: UIButton) {
        
    }
}
