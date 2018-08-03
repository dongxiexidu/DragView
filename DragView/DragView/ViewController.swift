//
//  ViewController.swift
//  DragView
//
//  Created by fashion on 2018/8/2.
//  Copyright © 2018年 shangZhu. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var dragView: DragView!
    @IBOutlet weak var bgView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dragView.hasNavagation = false
        dragView.forbidenEnterStatusBar = true
        dragView.fatherIsController = true
        
        dragView.clickDragViewBlock = { dragV in
            print("clickDragView-\(dragV)")
        }
        dragView.endDragBlock = { dragV in
            print("endDrag-\(dragV)")
        }
        dragView.beginDragBlock = { dragV in
            print("beginDrag-\(dragV)")
        }

    }

    override func viewDidLayoutSubviews() {

      //  dragView.freeRect = self.bgView.frame
    }
    


}

