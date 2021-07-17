//
//  LoginViewController.swift
//  Topical Dictionary
//
//  Created by İbrahim Ethem Karalı on 14.09.2020.
//  Copyright © 2020 İbrahim Ethem Karalı. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import FBSDKCoreKit
import GoogleSignIn
import CryptoKit
import AuthenticationServices

class LoginViewController: UIViewController, UIScrollViewDelegate, GIDSignInDelegate {
    
    fileprivate var currentNonce: String?

    
    // Definitiion of the components
    @IBOutlet weak var logoHeight: NSLayoutConstraint!
    
    @IBOutlet weak var bottomSpaceHeight: NSLayoutConstraint!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var appleButton: UIButton!
    @IBOutlet weak var googleButton: UIButton!
    
    let fbLoginManager = LoginManager()
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var tabbar: UITabBarController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let buttonRadius: CGFloat = 8.0
        
        appleButton.layer.cornerRadius = buttonRadius
        googleButton.layer.cornerRadius = buttonRadius
        loginButton.layer.cornerRadius = buttonRadius
        facebookButton.layer.cornerRadius = buttonRadius
        
        
        scrollView.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(somewhereTapped))
        self.view.addGestureRecognizer(tapGesture)
        
        GIDSignIn.sharedInstance()?.delegate = self
        
    }
    
    // MARK: Facebook login
    
    
    @IBAction func facebookLogin(_ sender: UIButton) {
        fbLoginManager.logIn(permissions: ["email", "public_profile"], from: self) { (loginResult, error) in
            if error != nil {
                print(error!)
            }
            
            if let currentToken = AccessToken.current {
                let credential = FacebookAuthProvider.credential(withAccessToken: currentToken.tokenString)
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    if let error = error as NSError? {
                        print(error)
                    } else {
                        DispatchQueue.main.async {
                            self.setupTabbar()
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Apple Login
    
    
    @IBAction func appleLogin(_ sender: UIButton) {
        startSignInWithAppleFlow()
    }
    
    // MARK: Google Login
    
    @IBAction func googleLogin(_ sender: UIButton) {
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print(error as Any)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        print("didSignFor")
        if error != nil {
            print(error!)
        } else {
            guard let authentication = user.authentication else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
            Auth.auth().signIn(with: credential) { (authDataResult, error) in
                if error != nil {
                    print(error!)
                    return
                }
                if let authResult = authDataResult {
                    print("user logged in with: \(authResult.user.uid)")
                }
            }
            
        }
    }
    
    // Login Helper
    // Setting tabbar to the first index and make the tab bar apear
    func setupTabbar() {
        if tabbar != nil {
            tabbar!.selectedIndex = 0
            tabbar!.tabBar.isHidden = false
        }
    }
    
    // MARK: - Text Field Functions
    
    
    @objc private func somewhereTapped() {
        view.endEditing(true)
    }
    
    
    // MARK: - Scroll View Functions
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //view.endEditing(true)
    }

}

extension UIScrollView {
    func scrollToView(view: UIView, animated: Bool) {
        if let origin = view.superview {
                    // Get the Y position of your child view
            let childStartPoint = origin.convert(view.frame.origin, to: self)
                    // Scroll to a rectangle starting at the Y of your subview, with a height of the scrollview
                    self.scrollRectToVisible(CGRect(x:0, y:childStartPoint.y,width: 1,height: self.frame.height), animated: animated)
                }
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      let charset: Array<Character> =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
      var result = ""
      var remainingLength = length

      while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
          var random: UInt8 = 0
          let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
          if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
          }
          return random
        }

        randoms.forEach { random in
          if remainingLength == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }

      return result
    }
    
    
    func startSignInWithAppleFlow() {
      let nonce = randomNonceString()
      currentNonce = nonce
      let appleIDProvider = ASAuthorizationAppleIDProvider()
      let request = appleIDProvider.createRequest()
      request.requestedScopes = [.fullName, .email]
      request.nonce = sha256(nonce)

      let authorizationController = ASAuthorizationController(authorizationRequests: [request])
      authorizationController.delegate = self
      authorizationController.presentationContextProvider = self
      authorizationController.performRequests()
    }

    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
      }.joined()

      return hashString
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
              guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
              }
              guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
              }
              guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
              }
              // Initialize a Firebase credential.
              let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                        idToken: idTokenString,
                                                        rawNonce: nonce)
              // Sign in with Firebase.
              Auth.auth().signIn(with: credential) { (authResult, error) in
                if error != nil {
                  print(error!.localizedDescription)
                  return
                }
                print("User logged in via Apple login with id: \(authResult?.user.uid ?? "nil")")
              }
            }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let message = error.localizedDescription
        let alert = UIAlertController(title: "Something went wrong", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .cancel, handler: { _ in alert.dismiss(animated: true, completion: nil) }))
        self.present(alert, animated: true, completion: nil)
    }
}
