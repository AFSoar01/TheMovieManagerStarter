//
//  LoginViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginViaWebsiteButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    //Once the login button is tapped, it gets a request Token using the getRequestToken method (it's completion handler passes a Bool if the parsing was sucessful), once the getRequestToken data session is complete, it's completion handler calls the handleRequestTokenResponse method, which takes two inputs: success and error, and simply prints the requestToken we downloaded
    @IBAction func loginTapped(_ sender: UIButton) {
        TMDBClient.getRequestToken(completion: handleRequestTokenResponse(success:error:))
    }
    
    @IBAction func loginViaWebsiteTapped() {
        performSegue(withIdentifier: "completeLogin", sender: nil)
    }
    
    func handleRequestTokenResponse(success:Bool, error: Error?) {
        if success {
            //print(TMDBClient.Auth.requestToken)
            //Required a reference to self for the variables below since they're global properties
            DispatchQueue.main.async {
                //print("Calling Login Function")
            TMDBClient.login(username: self.emailTextField.text ?? "", password: self.passwordTextField.text ?? "", completion: self.handleLoginResponse(success:Error:))
            }

        }
    }
    
    func handleLoginResponse(success: Bool, Error: Error?) {
        //print("Handle Login Response Works")
        if success {
            //print("Create Session ID is Called")
            TMDBClient.createSessionId(completion: handleSessionResponse(success:Error:))
        }
    }
    
    func handleSessionResponse(success: Bool, Error: Error?) {
        //print("Handle Session Response Works")
        if success {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "completeLogin", sender: nil)
            }
        }
        
    }
    

}
