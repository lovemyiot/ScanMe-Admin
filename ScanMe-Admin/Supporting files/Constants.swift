//
//  Constants.swift
//  ScanMe - NFC reader
//
//  Created by Jacek Kopaczel on 22/07/2021.
//

import Foundation

enum DescriptionKeys {
    // MARK: - NFC session
    static let sessionAlert = "Hold your iPhone near the item to see what happens."
    static let tooManyTags = "More than 1 tag detected. Please remove other items and try again."
    static let connectionFailed = "Connection failed. Try again."
    
    // MARK: - Device support
    static let scanningNotSupported = "This device doesn't support tag scanning."
    static let scanningNotSupportedTitle = "Scanning Not Supported"
    static let smsNotSupported = "This device doesn't support sending text messages."
    static let smsNotSupportedTitle = "SMS Not Supported"
    
    // MARK: - Command support
    static let commandNotSupported = "Received command is not supported."
    static let commandNotSupportedTitle = "Command Not Supported"
    
    // MARK: - Command validation
    static let nonValidParameters = "Received parameters are not valid."
    static let validationError = "Validation Error"
    
    // MARK: - Command names
    static let flashlight = "Toggle flashlight"
    static let textMessage = "Send text message"
    static let openUrl = "Open URL"
    static let call = "Make a call"
    static let unsupported = "Unsupported"
    static let wifi = "Connect to WiFi"
    
    // MARK: - Running command error
    static let wifiError = "WiFi connection error"
    static let couldNotConnectToWifi = "Could not connect to WiFi. Please try again."
    
    // MARK: - Saving command
    static let numberOfTags = "Number of tags to save"
    static let saveOneOrMore = "Do you want to save only one tag at once or more ?"
    static let writingErrorTitle = "Error writing command"
    static let writingError = "Could not write data to Firestore."
    static let writingSuccessTitle = "Success writing command"
    static let writingSuccess = "Successfully wrote data to Firestore!"
    
    // MARK: - Firebase auth
    static let authErrorTitle = "Authentication error"
    static let authError = "Could not authenticate to Firebase."
}

enum FirestoreKeys {
    static let tagsCollection = "tags"
}
