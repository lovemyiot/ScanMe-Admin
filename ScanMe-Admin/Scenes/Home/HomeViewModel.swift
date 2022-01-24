//
//  HomeViewModel.swift
//  ScanMe - NFC reader
//
//  Created by Jacek Kopaczel on 22/07/2021.
//

import XCoordinator
import MessageUI
import AVFoundation
import NetworkExtension
import MapKit

class HomeViewModel: NSObject {
    private let router: UnownedRouter<MainRoute>
    var identifiers: [String] = []

    var onAlert: ((String, String) -> Void)?
    
    init(router: UnownedRouter<MainRoute>) {
        self.router = router
    }
    
    func resetData() {
        identifiers = []
    }
    
    func goToSaveCommand() {
        router.trigger(.saveCommand(identifiers: identifiers))
    }

    func fetchCommand(for identifier: String, completion: @escaping (CommandDetailsResponse?) -> Void) {
        DataManager.shared.fetchCommand(for: identifier, from: FirestoreKeys.tagsCollection) { [weak self] in
            var details: CommandDetailsResponse?
            switch $0 {
            case .success(let commandDetails):
                print("Command details for tag \(identifier): \(commandDetails)")
                details = commandDetails
            case .failure(let error):
                switch error {
                case .decodingError:
                    print("Error decoding response from Firestore!")
                case .documentNotExist:
                    print("Document does not exist in Firestore!")
                    self?.onAlert?(DescriptionKeys.tagNotSupportedTitle, DescriptionKeys.tagNotSupported)
                }
            }
            completion(details)
        }
    }

    func processCommand(_ commandDetails: CommandDetailsResponse, completion: @escaping () -> Void) {
        CommandManager.shared.processCommands(commandDetails) { [weak self] command in
            guard let safeCommand = command else {
                print("Error processing command!")
                return
            }
            switch safeCommand {
            case .flashlight:
                self?.toggleFlashlight()

            case let .textMessage(phoneNumber, message):
                self?.sendText(message: message, to: phoneNumber)

            case .openUrl(let url):
                self?.open(url)

            case .call(let phoneNumber):
                self?.call(phoneNumber)
                
            case let .wifi(ssid,password):
                self?.connectToWifi(ssid: ssid, password: password)
                
            case .unsupported:
                self?.onAlert?(DescriptionKeys.commandNotSupportedTitle, DescriptionKeys.commandNotSupported)
                
            case let .openMap(coordinates, destination):
                self?.openMap(latitude: coordinates?.latitude, longitude: coordinates?.longitude, destination: destination)
            }
            completion()
        }
    }
    
    private func openMap(latitude: Double?, longitude: Double?, destination: String?) {
        guard let latitude = latitude, let longitude = longitude, let destination = destination else {
            onAlert?(DescriptionKeys.validationError, DescriptionKeys.nonValidParameters)
            return
        }
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinates)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = destination
        mapItem.openInMaps(launchOptions: nil)
    }
    
    private func connectToWifi(ssid: String?, password: String?) {
        guard let ssid = ssid, let password = password else {
            onAlert?(DescriptionKeys.validationError, DescriptionKeys.nonValidParameters)
            return
        }
        let configuration = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
        NEHotspotConfigurationManager.shared.apply(configuration) { [weak self] error in
            if let error = error as NSError?,
               error.domain == NEHotspotConfigurationErrorDomain {
                switch error.code {
                case NEHotspotConfigurationError.alreadyAssociated.rawValue:
                    print("Specified WiFi is already associated")
                case NEHotspotConfigurationError.userDenied.rawValue:
                    print("User denied connecting to WiFi")
                default:
                    self?.onAlert?(DescriptionKeys.wifiError, DescriptionKeys.couldNotConnectToWifi)
                }
                return
            }
            print("Successfully connected to WiFi: \(ssid)")
        }
    }

    private func call(_ phoneNumber: String?) {
        guard let phoneNumber = phoneNumber, let phoneNumberUrl = URL(string: "tel://\(phoneNumber)") else {
            onAlert?(DescriptionKeys.validationError, DescriptionKeys.nonValidParameters)
            return
        }
        UIApplication.shared.open(phoneNumberUrl)
    }

    private func toggleFlashlight(mode: AVCaptureDevice.TorchMode? = nil) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                guard let mode = mode else {
                    device.torchMode = device.torchMode == .off ? .on : .off
                    device.unlockForConfiguration()
                    return
                }
                device.torchMode = mode
                device.unlockForConfiguration()
            } catch {
                print("Flashlight could not be used.")
            }
        } else {
            print("Flashlight is not available on this device.")
        }
    }

    private func sendText(message: String?, to phoneNumber: String?) {
        guard let phoneNumber = phoneNumber, let message = message else {
            onAlert?(DescriptionKeys.validationError, DescriptionKeys.nonValidParameters)
            return
        }
        if MFMessageComposeViewController.canSendText() {
            router.trigger(.textMessage(message: message, phoneNumber: phoneNumber, delegate: self))
        } else {
            onAlert?(DescriptionKeys.smsNotSupportedTitle, DescriptionKeys.smsNotSupported)
        }
    }

    private func open(_ url: URL?) {
        guard let url = url else {
            onAlert?(DescriptionKeys.validationError, DescriptionKeys.nonValidParameters)
            return
        }
        UIApplication.shared.open(url)
    }
}

// MARK: - MFMessageComposeViewControllerDelegate
extension HomeViewModel: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}
