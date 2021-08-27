//
//  MainCoordinator.swift
//  ScanMe - NFC reader
//
//  Created by Jacek Kopaczel on 28/07/2021.
//

import Foundation
import XCoordinator

enum MainRoute: Route {
    case home
    case back
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
            
        case .back:
            return .pop()
        }
    }
}
