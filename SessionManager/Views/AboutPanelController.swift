//
//  AboutPanelController.swift
//  SLC
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa

class AboutPanelController: NSWindowController {

    weak var appDelegate:AppDelegate!

    @IBOutlet weak var iconButton: NSButton!
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var copyrightLabel: NSTextField!
    
    @IBAction func openLoginPanel(_ sender: Any) {
        if Config.shared.allowExtend {
            appDelegate.openExtendPanel()
            window?.close()
            return
        }
        
        if appDelegate.openLoginPanel() {
            window?.close()
        }
    }

    override func close() {
        print("close About")
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        setup()
    }
    
    func setup() {
        var appIcon = NSImage(named: "AppIcon")
        
        if let iconURL = Config.shared.applicationIcon, let iconImage = NSImage(contentsOf: iconURL) {
            appIcon = iconImage
        }

        iconButton.image = appIcon
        nameField.stringValue = Config.shared.dialogAboutText1
        versionLabel.stringValue = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        copyrightLabel.stringValue = Config.shared.dialogAboutText2

        appDelegate = NSApplication.shared.delegate as? AppDelegate
       
        if appDelegate == nil {
            print("Error: no app delegate")
        }
    }
}
