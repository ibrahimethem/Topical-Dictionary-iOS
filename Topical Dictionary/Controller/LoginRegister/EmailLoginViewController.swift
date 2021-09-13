//
//  EmailLoginViewController.swift
//  Topical Dictionary
//
//  Created by İbrahim Ethem Karalı on 1.02.2021.
//  Copyright © 2021 İbrahim Ethem Karalı. All rights reserved.
//

import UIKit
import FirebaseAuth

class EmailLoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var loginOrRegisterSegment: UISegmentedControl!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginTextfields: UIStackView!
    @IBOutlet weak var fullnameTextField: UITextField!
    
    @IBOutlet weak var privacyPolicy: UILabel! // add real terms and conditions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emailTextField.delegate = self
        emailTextField.tag = 1
        passwordTextField.delegate = self
        passwordTextField.tag = 2
        confirmPasswordTextField.delegate = self
        confirmPasswordTextField.tag = 3
        fullnameTextField.delegate = self
        fullnameTextField.tag = 0
        
        loginButton.layer.cornerRadius = 8.0
        
        let privacyText = NSMutableAttributedString(string: "When you singned up using email, you are accepting the Topical Dictionaries' ", attributes: [.foregroundColor: UIColor.label])
        let link = NSAttributedString(string: "Privacy Policy",
                                      attributes: [.link: "https://topicaldictionary.ethemkarali.com/privacy.html"])
        privacyText.append(link)
        privacyPolicy.attributedText = privacyText
        privacyPolicy.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPrivacyPolicy)))
        
    }
    
    @objc func didTapPrivacyPolicy() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PrivacyViewController")
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func loginOrRegister(_ sender: UISegmentedControl) {
        view.endEditing(true)
        if sender.selectedSegmentIndex == 0 {
            loginButton.setTitle("Sign in with Email", for: .normal)
            UIView.animate(withDuration: 0.4) {
                self.fullnameTextField.isHidden = true
                self.confirmPasswordTextField.isHidden = true
                self.confirmPasswordTextField.isEnabled = false
                self.privacyPolicy.isHidden = true
                self.passwordTextField.textContentType = .password
            }
        } else {
            loginButton.setTitle("Sign up with Email", for: .normal)
            UIView.animate(withDuration: 0.4) {
                self.fullnameTextField.isHidden = false
                self.confirmPasswordTextField.isHidden = false
                self.confirmPasswordTextField.isEnabled = true
                self.privacyPolicy.isHidden = false
                self.passwordTextField.textContentType = .newPassword
            }
        }
    }
    
    @IBAction func login(_ sender: UIButton) {
        if loginOrRegisterSegment.isHidden {
            UIView.animate(withDuration: 0.3) {
                self.loginTextfields.isHidden = false
                self.loginOrRegisterSegment.isHidden = false
                self.privacyPolicy.isHidden = false
                return
            }
        }
        
        if loginOrRegisterSegment.selectedSegmentIndex == 0 {
            // Login
            view.isUserInteractionEnabled = false
            Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (authDataResult, error) in
                if error != nil {
                    print("Error while signin: \(error!)")
                    let alert = UIAlertController(title: "Have an issue", message: error?.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    
                    self.present(alert, animated: true, completion: nil)
                    self.view.isUserInteractionEnabled = true
                    
                    return
                }
                
                if let authDataRes = authDataResult {
                    print("user signed in: UID: \(authDataRes.user.uid)")
                    print("is email verified: \(authDataRes.user.isEmailVerified)")
                    DispatchQueue.main.async {
                        //self.setupTabbar()
                        self.dismiss(animated: true, completion: nil)
                    }
                }
                self.view.isUserInteractionEnabled = true
            }
            
        } else {
            if let password = passwordTextField.text,
               password == confirmPasswordTextField.text,
               let email = emailTextField.text, let name = fullnameTextField.text {
                Auth.auth().createUser(withEmail: email, password: password) { authDataResult, error in
                    if let err = error {
                        print(err.localizedDescription)
                        return
                    }
                    DispatchQueue.main.async {
                        authDataResult?.user.createProfileChangeRequest().displayName = name
                    }
                }
            } else {
                print("Passwords doesn't match")
            }
        }
    }
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
