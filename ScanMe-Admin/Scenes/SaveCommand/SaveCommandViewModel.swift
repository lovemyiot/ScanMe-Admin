//
//  SaveCommandViewModel.swift
//  ScanMe-Admin
//
//  Created by jacek.kopaczel on 27/08/2021.
//

import XCoordinator

class SaveCommandViewModel {
    private let router: UnownedRouter<MainRoute>
    
    init(router: UnownedRouter<MainRoute>) {
        self.router = router
    }
}
