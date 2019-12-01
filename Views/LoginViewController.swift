//
//  LoginViewController.swift
//  Peynir
//
//  Created by tolga on 11/24/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    private let loginManager: LoginManagerInterface
    private let userInfoManager: UserInfoManagerInterface

    private var usernameField: UITextField!
    private var passwordField: UITextField!
    private var loginButton: UIButton!
    private var spinner: UIActivityIndicatorView!

    init(loginManager: LoginManagerInterface, userInfoManager: UserInfoManagerInterface) {
        self.loginManager = loginManager
        self.userInfoManager = userInfoManager

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemBackground

        let usernameField = UITextField()
        usernameField.placeholder = "username (e1234567)"

        let passwordField = UITextField()
        passwordField.placeholder = "password"
        passwordField.isSecureTextEntry = true

        let loginButton = UIButton(type: .roundedRect)
        loginButton.layer.borderColor = UIColor.label.cgColor
        loginButton.layer.borderWidth = 1
        loginButton.layer.cornerRadius = 2
        loginButton.setTitle("login", for: .normal)
        loginButton.setTitleColor(.label, for: .normal)
        loginButton.setTitleColor(UIColor.label.withAlphaComponent(0.2), for: .disabled)
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        loginButton.addSubview(spinner)

        [usernameField, passwordField, loginButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview($0)

            $0.addTarget(self, action: #selector(didUpdateText), for: .editingChanged)
        }

        [usernameField, passwordField].forEach {
            $0.textColor = .label
            $0.borderStyle = .bezel
            $0.autocapitalizationType = .none
            $0.autocorrectionType = .no
        }

        usernameField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: Consts.horizontalPadding).isActive = true
        usernameField.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -Consts.horizontalPadding).isActive = true
        usernameField.topAnchor.constraint(equalTo: self.view.topAnchor, constant: Consts.topPadding).isActive = true
        usernameField.heightAnchor.constraint(equalToConstant: Consts.inputElementHeight).isActive = true

        passwordField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: Consts.horizontalPadding).isActive = true
        passwordField.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -Consts.horizontalPadding).isActive = true
        passwordField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: Consts.verticalPadding).isActive = true
        passwordField.heightAnchor.constraint(equalToConstant: Consts.inputElementHeight).isActive = true

        loginButton.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor).isActive = true
        loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: Consts.verticalPadding).isActive = true
        loginButton.widthAnchor.constraint(equalToConstant: Consts.loginButtonWidth).isActive = true
        loginButton.heightAnchor.constraint(equalToConstant: Consts.inputElementHeight).isActive = true

        spinner.centerXAnchor.constraint(equalTo: loginButton.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor).isActive = true
        spinner.heightAnchor.constraint(equalTo: loginButton.heightAnchor).isActive = true
        spinner.widthAnchor.constraint(equalTo: spinner.heightAnchor).isActive = true

        self.usernameField = usernameField
        self.passwordField = passwordField
        self.loginButton = loginButton
        self.spinner = spinner
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateLoginButton()
    }

    @objc func didUpdateText() {
        self.updateLoginButton()
    }

    @objc func didTapLogin() {
        guard
            let username = self.usernameField.text, username.count > 0,
            let password = self.passwordField.text, password.count > 0 else {
                return
        }

        self.spinner.startAnimating()
        self.loginManager.login(username: username, password: password) { loggedIn, error in
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                if loggedIn {
                    self.userInfoManager.saveUserCredentials(newCredentials: UserCredentials(username: username, password: password))
                }
            }
        }
    }
}

private extension LoginViewController {
    struct Consts {
        static let topPadding: CGFloat = 200
        static let horizontalPadding: CGFloat = 60
        static let verticalPadding: CGFloat = 10
        static let inputElementHeight: CGFloat = 44
        static let loginButtonWidth: CGFloat = 100
    }

    func updateLoginButton() {
        let username = self.usernameField.text ?? ""
        let password = self.passwordField.text ?? ""
        self.loginButton.isEnabled = (!username.isEmpty && !password.isEmpty)
    }
}
