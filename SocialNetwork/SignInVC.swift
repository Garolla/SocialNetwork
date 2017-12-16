//
//  SignInVC.swift
//  SocialNetwork
//
//  Created by Emanuele Garolla on 18/08/2017.
//  Copyright © 2017 Emanuele Garolla. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import SwiftKeychainWrapper

class SignInVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailFld: FancyField!
    @IBOutlet weak var pwdFld: FancyField!

    override func viewDidLoad() {
        super.viewDidLoad()
       
        // To dismiss keyboard
        emailFld.delegate = self
        pwdFld.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let _ = KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID){
            performSegue(withIdentifier: "goToFeed", sender: nil)
        }
    }
    
    
    @IBAction func facebookBtnTapped(_ sender: Any) {
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if error != nil {
                print("GARO: Unable to authencitcate with Facebook")
            } else if result?.isCancelled == true {
                print("GARO: User cancelled Facebook authentication")
            } else {
                print("GARO: Successfully authenticated with Facebook")
                let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                self.firebaseAuth(credential)
            }
        }
    }
    
    func firebaseAuth(_ credential: AuthCredential) {
        Auth.auth().signIn(with: credential, completion: { (user, error) in
            if error != nil {
                print("GARO: Unable to authenticate with Firebase - \(error)")
            } else {
                print("GARO: Successfully authenticated with Firebase")
                if let user = user {
                    let userData = ["provider": credential.provider]
                    self.completeSignIn(id: user.uid, userData: userData)
                }
            }
        })
    }
    
    @IBAction func signInTapped(_ sender: Any) {
        if let email = emailFld.text, let pwd = pwdFld.text{
            Auth.auth().signIn(withEmail: email, password: pwd, completion: { (user, error) in
                if error == nil {
                    print("GARO: Email user authenticated with Firebase")
                    if let user = user {
                        self.checkEmailVerification(user: user)
                    }
                } else {
                    Auth.auth().createUser(withEmail: email, password: pwd, completion: { (user, error) in
                        if error != nil {
                            print("GARO: Unable to authenticate with Firebase using email")
                        } else {
                            print("GARO: Successfully authenticated with Firebase using email")
                            if let user = user {
                                self.checkEmailVerification(user: user)
                            }
                        }
                    })
                }
            })
        }
    }
    
    func checkEmailVerification(user: AnyObject) {
        if !user.isEmailVerified {
            Auth.auth().currentUser?.sendEmailVerification { (error) in
                if error != nil {
                    print("GARO: Unable to send the Email Verification")
                } else {
                    print("GARO: Email Verification sent")
                }
            }
        } else {
            let userData = ["provider": user.providerID]
            self.completeSignIn(id: user.uid, userData: userData as! Dictionary<String, String>)
        }
    }
    
    func completeSignIn(id: String, userData: Dictionary<String, String> ) {
        DataService.ds.createFirbaseDBUser(uid: id, userData: userData)
        
        let keychainResult = KeychainWrapper.defaultKeychainWrapper.set(id, forKey: KEY_UID)
        print("GARO: Data saved to keychain \(keychainResult)")
        performSegue(withIdentifier: "goToFeed", sender: nil)
    }
    
    
    //To dismiss the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

