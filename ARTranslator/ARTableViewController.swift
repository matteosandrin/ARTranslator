//
//  ARTableViewController.swift
//  ARTranslator
//
//  Created by Matteo Sandrin on 23/03/2018.
//  Copyright © 2018 CompanyName. All rights reserved.
//

import UIKit
import ROGoogleTranslate

class ARTableViewController: UITableViewController {

    let langs = ROGoogleTranslate().languages()
    var currentLang: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        let indexPath = NSIndexPath(item: currentLang, section: 0)
        tableView.scrollToRow(at: indexPath as IndexPath, at: UITableViewScrollPosition.middle, animated: true)
        
        print(currentLang)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return langs.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCell(withIdentifier: "cell")
        let lang = langs[indexPath.row] as? [String:String]
        cell?.textLabel?.text = lang!["name"] as! String
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Hello")
        let controller: ViewController = self.presentingViewController as! ViewController
        controller.currentLang = indexPath.row
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Dismiss"), object: nil)
        self.dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == self.currentLang {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.middle)
        }
    }

}
