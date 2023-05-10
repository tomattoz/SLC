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
        iconButton.image = NSImage.init(named: "AppIcon")!
        nameField.stringValue = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
        versionLabel.stringValue = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        copyrightLabel.stringValue = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? ""

        
        
        appDelegate = NSApplication.shared.delegate as? AppDelegate
        if appDelegate == nil {
            print("Error: no app delegate")
        }
    }
}
