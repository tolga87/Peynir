//
//  HomeViewController.swift
//  Peynir
//
//  Created by tolga on 11/24/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.7)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Home"
        label.textColor = .label
        label.textAlignment = .center
        self.view.addSubview(label)

        label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        label.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 100).isActive = true
        label.widthAnchor.constraint(equalToConstant: 200).isActive = true
        label.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let button = UIButton(type: .roundedRect)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.borderColor = UIColor.label.cgColor
        button.layer.borderWidth = 2
        button.setTitle("Fetch Categories🏃", for: .normal)
        button.addTarget(self, action: #selector(debugButtonDidTap), for: .touchUpInside)
        self.view.addSubview(button)

        button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        button.widthAnchor.constraint(equalToConstant: 200).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//https://discourse.ceng.metu.edu.tr/

    }

    @objc func debugButtonDidTap() {
        let networkManager = NetworkManager()
        networkManager.getString(atUrl: "https://discourse.ceng.metu.edu.tr/categories.json") { result in
            guard let json = try? result.successValue?.toJson() else {
                return
            }
            json.prettyPrint()
        }
    }
}
