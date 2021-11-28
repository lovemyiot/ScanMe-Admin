//
//  MainCoordinator.swift
//  ScanMe - NFC reader
//
//  Created by Jacek Kopaczel on 28/07/2021.
//

import Foundation
import XCoordinator
import MessageUI

enum MainRoute: Route {
    case home
    case saveCommand(identifiers: [String])
    case back
    case textMessage(message: String, phoneNumber: String, delegate: MFMessageComposeViewControllerDelegate)
}

class MainCoordinator: NavigationCoordinator<MainRoute> {
    init() {
        super.init(initialRoute: .home)
        rootViewController.modalPresentationStyle = .fullScreen
    }
    
    override func prepareTransition(for route: MainRoute) -> NavigationTransition {
        switch route {
        case .home:
            let viewController: HomeViewController = HomeViewController.instantiate()
            viewController.viewModel = HomeViewModel(router: unownedRouter)
            return .push(viewController)
            
        case let .saveCommand(identifiers):
            let viewController: SaveCommandViewController = SaveCommandViewController.instantiate()
            viewController.viewModel = SaveCommandViewModel(router: unownedRouter, identifiers: identifiers)
            return .push(viewController)
            
        case .back:
            return .pop()
            
        case let .textMessage(message, phoneNumber, delegate):
            guard MFMessageComposeViewController.canSendText() else {
                return .none()
            }
            let messageViewController = MFMessageComposeViewController()
            messageViewController.body = message
            messageViewController.recipients = [phoneNumber]
            messageViewController.messageComposeDelegate = delegate
            return .present(messageViewController)
        }
    }
}
