//
//  LoginPanelController.swift
//  Sarah Lawrence College Manager
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa

class LoginPanelController: NSWindowController, NSTextFieldDelegate, NSControlTextEditingDelegate {
    
    weak var appDelegate:AppDelegate!
    @IBOutlet weak var textlabel: NSTextField!
    
    @IBOutlet weak var usernameTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var loginButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    
    var usersCredentials:Dictionary<String, String>?
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    override func awakeFromNib() {

        super.awakeFromNib()

    }
    
    func setup() {
        
        usernameTextField.focusRingType = .none
        passwordTextField.focusRingType = .none
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        loginButton.target = self
        cancelButton.target = self
        loginButton.action = #selector(LoginPanelController.validateCredentials)
        cancelButton.action = #selector(LoginPanelController.cancelLogin)
        textlabel.stringValue = ""
        //usernameTextField.focusRingMaskBounds = .
        appDelegate = NSApplication.shared.delegate as? AppDelegate
        if appDelegate == nil {
            print("Error: no app delegate")
        }
        self.window?.isMovable = true
        
        let path = appDelegate.usersPlistURL.path
        if !FileManager.default.fileExists(atPath: path) {
            appDelegate.cancelLogin(true)
            NSAlert(error: "Can't find Users plist").runModal()

        } else {
            let plistDictionary = NSDictionary(contentsOfFile: path) as? Dictionary<String, String>
          
            if plistDictionary == nil {
                appDelegate.cancelLogin(true)
                NSAlert(error: "Error reading Users plist").runModal()
            } else {
                usersCredentials = plistDictionary
            }
        }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSStandardKeyBindingResponding.insertTab(_:)):
            return false
        case #selector(NSStandardKeyBindingResponding.insertNewline(_:)):
            //usernameTextField.resignFirstResponder()
            usernameTextField.currentEditor()?.selectedRange = NSRange.init(location: usernameTextField.stringValue.count-1, length: 0)
            //passwordTextField.resignFirstResponder()
            validateCredentials()
            return false
//        case #selector(NSStandardKeyBindingResponding.cancelOperation(_:)):
//            return false
//        case #selector(NSStandardKeyBindingResponding.moveLeft(_:)):
//            return false
//        case #selector(NSStandardKeyBindingResponding.deleteBackward(_:)):
//            return false
//        case #selector(NSStandardKeyBindingResponding.moveRight(_:)):
//            return false
        default:
            ()
        
        }
        print("\(commandSelector)")
        return false
    }
    
    @objc func cancelLogin() {
        appDelegate.cancelLogin(false)
    }
    
    @objc func validateCredentials() {

//        self.window?.close() // fix
//        self.appDelegate.completeLogin() //fix

        let name = usernameTextField.stringValue
        print("usernameValidator result: \(name)")
        
        if usersCredentials![name] == nil {
            DispatchQueue.main.async{
                self.textlabel.stringValue = "no such user"

                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                    self.textlabel.stringValue = ""
                })
            }
            return
        } else if (usersCredentials![name]!).compare(passwordTextField.stringValue) != .orderedSame{
            DispatchQueue.main.async{
                self.textlabel.stringValue = "Wrong pasword"

                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                    self.textlabel.stringValue = ""
                })
            }
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.window?.close()
            self.appDelegate.completeLogin()
        })
    }
}
