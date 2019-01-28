//
//  ViewController.swift
//  CodeCoverage
//
//  Created by Derek Selander on 1/27/19.
//  Copyright © 2019 Derek Selander. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var v : UIView? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        print("yay")
        
        if self.v == nil {
            print("v is nil!")
        }
        else {
            print("v is not nil!")
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    func doSomeShit() {
        print("did this work?")
    }

}

