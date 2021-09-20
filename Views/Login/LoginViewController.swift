//
//  LoginViewController.swift
//  Peynir
//
//  Created by tolga on 11/24/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Combine
import PromiseKit
import UIKit

public struct LoginViewState: ViewState {
    var username: String
    var password: String
    var isInputValid: Bool
    var isLoading: Bool

    init(username: String = "", password: String = "", isInputValid: Bool = false, isLoading: Bool = false) {
        self.username = username
        self.password = password
        self.isInputValid = isInputValid
        self.isLoading = isLoading
    }
}

public enum LoginViewAction: ViewAction {
    case loginRequested
    case textEntered(username: String, password: String)
}

class LoginViewController: ViewController<LoginViewState, LoginViewAction, LoginEvent> {
    private lazy var usernameField: UserCredentialTextField = {
        let field = UserCredentialTextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = "username (e1234567)"
        return field
    }()

    private lazy var passwordField: UserCredentialTextField = {
        let field = UserCredentialTextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = "password"
        field.isSecureTextEntry = true
        return field
    }()

    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.borderColor = UIColor.label.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 4
        button.setTitle("Sign In", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        return button
    }()

    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        return spinner
    }()

    private var usernameInput: String {
        return self.usernameField.text ?? ""
    }

    private var passwordInput: String {
        return self.passwordField.text ?? ""
    }

    init(presenter: LoginPresenter) {
        super.init(presenter: presenter)

        presenter.displayAlertCallback = { [weak self] message in
            guard let self = self else { return }

            let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemBackground

        loginButton.addSubview(spinner)
        [usernameField, passwordField, loginButton].forEach {
            self.view.addSubview($0)
        }

        [usernameField, passwordField].forEach {
            $0.textColor = .label
            $0.tintColor = UIColor(hex: "22b455")
            $0.layer.borderWidth = 1
            $0.layer.cornerRadius = 4
            $0.layer.borderColor = UIColor.label.cgColor
            $0.autocapitalizationType = .none
            $0.autocorrectionType = .no
            $0.addTarget(self, action: #selector(didUpdateText), for: .editingChanged)
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
        loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 1.5 * Consts.verticalPadding).isActive = true
        loginButton.widthAnchor.constraint(equalToConstant: Consts.loginButtonWidth).isActive = true
        loginButton.heightAnchor.constraint(equalToConstant: Consts.inputElementHeight).isActive = true

        spinner.constrainToCenter(ofView: loginButton)
        spinner.heightAnchor.constraint(equalTo: loginButton.heightAnchor).isActive = true
        spinner.widthAnchor.constraint(equalTo: spinner.heightAnchor).isActive = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateView(state: self.presenter.viewState)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.usernameField.becomeFirstResponder()
    }

    func updateView(state: LoginViewState) {
        self.usernameField.text = state.username
        self.passwordField.text = state.password
        self.loginButton.isEnabled = state.isInputValid
        self.loginButton.alpha = state.isInputValid ? 1 : 0.35

        if state.isLoading {
            self.spinner.startAnimating()
        } else {
            self.spinner.stopAnimating()
        }
    }

    @objc func didUpdateText() {
        self.presenter.handleAction(.textEntered(username: self.usernameInput, password: self.passwordInput))
    }

    @objc func didTapLogin() {
        self.presenter.handleAction(.loginRequested)
    }

    override func handle(viewState: LoginViewState) {
        self.updateView(state: viewState)
    }
}

private extension LoginViewController {
    struct Consts {
        static let topPadding: CGFloat = 200
        static let horizontalPadding: CGFloat = 60
        static let verticalPadding: CGFloat = 10
        static let inputElementHeight: CGFloat = 44
        static let loginButtonWidth: CGFloat = 120
    }
}
