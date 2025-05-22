//
//  ViewController.swift
//  iMediaPhotosAppDemo
//
//  Created by Kunihiko Ohnaka on 2025/05/22.
//

import Cocoa
import iMedia

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("Hello")

        let libcontroller = iMedia.IMBLibraryController(mediaType: kIMBMediaTypeImage)
        let topNodes = libcontroller?.topLevelNodesWithoutAccessRights() as? [IMBNode] ?? []
        printNodeTree(topNodes)
    }
    
    private func printNodeTree(_ nodes: [IMBNode]) {
        nodes.forEach { node in
            print("identifier=" + (node.identifier ?? "unknown") + "\n")
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

