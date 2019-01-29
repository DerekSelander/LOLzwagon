//
//  ViewController.swift
//  CodeCoverage
//
//  Created by Derek Selander on 1/27/19.
//  Copyright © 2019 Derek Selander. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var v : UIView? = UIView()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ifInputMethod(input: false)
        if self.v == nil {
            print("v is nil!")
        }
        else {
            print("v is not nil!")
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    func doSomeStuff() {
        print("did this work?")
    }
    
    func ifInputMethod(input : Bool) {
        if input {
            print("do something")
        } else {
            print("do something else")
        }
    }
    
//    func ifLetMethod() {
//        if let g = self.v {
//            print("do something \(g)")
//        } else {
//            print("do something else")
//        }
//    }

}

