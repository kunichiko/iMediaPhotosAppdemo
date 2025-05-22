//
//  ViewController.swift
//  iMediaPhotosAppDemo
//
//  Created by Kunihiko Ohnaka on 2025/05/22.
//

import Cocoa
import iMedia
import Photos

class ViewController: NSViewController {

    var librarycontroller: IMBLibraryController? = nil
    
    @IBOutlet weak var outlineView: NSOutlineView!

    var rootNodes: [IMBNode] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        PHPhotoLibrary.requestAuthorization { status in
            print("Photo Library access status: \(status)")
            print("\(PHAuthorizationStatus.denied) = denied")
            print("\(PHAuthorizationStatus.authorized) = authorized")

            DispatchQueue.main.async {
                IMBParserController.shared().delegate = self
                IMBParserController.shared().loadParserMessengers()
                
                self.librarycontroller = iMedia.IMBLibraryController(mediaType: kIMBMediaTypeImage)
                guard let l = self.librarycontroller else {
                    print("Failed to load library controller.")
                    return
                }
                l.delegate = self
                l.reload()
            }
        }
    }
    
    private func printNodeTree(_ nodes: [IMBNode], _ level: Int ) {
        let indent = String(repeating: "  ", count: level) // スペース2個 × level
        nodes.forEach { node in
            print("\(indent)identifier=" + (node.identifier ?? "unknown"))
            if let subnodes = node.subnodes as? [IMBNode] {
                printNodeTree(subnodes, level+1)
            }
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


    @IBAction func buttonClicked(_ sender: Any) {
        print("Hello")

        
        guard let t = librarycontroller?.subnodes, let topNodes = t as? [IMBNode] else {
            print("error")
            return
        }

        if let photosNode = findPhotosNode(fromNodes: topNodes) {
            let identifier = photosNode.identifier
            print("✅ Found Photos node: \(String(describing: identifier))")

            // Photosノードの中身を読み込む
            let start = Date()
            librarycontroller?.populateNode(photosNode) { e in
                print("⚠️ populate error: \(String(describing: e))")
            }
            let end = Date()
            print("populate took \(end.timeIntervalSince(start)) seconds")

            printNodeTree(topNodes, 1)

            self.rootNodes = [photosNode]
            self.outlineView.reloadData()
        }
    }
    
    private func findPhotosNode(fromNodes nodes: [IMBNode]) -> IMBNode? {
        for node in nodes {
            if let identifier = node.identifier, identifier.contains("com.apple.Photos") {
                return node
            }
            if let subnodes = node.subnodes as? [IMBNode] , let foundNode = self.findPhotosNode(fromNodes:subnodes) {
                return foundNode
            }
        }
        
        return nil
    }
}

extension ViewController : IMBLibraryControllerDelegate {
    
    func libraryController(_ inController: IMBLibraryController!, didCreateNode inNode: IMBNode!, with inParserMessenger: IMBParserMessenger!) {
        print("libraryController didCreateNode: \(String(describing: inNode))")
    }

    func libraryController(_ inController: IMBLibraryController!, didPopulateNode inNode: IMBNode!) {
        print("libraryController didPopulateNode: \(String(describing: inNode))")
    }
}

extension ViewController : IMBParserControllerDelegate {
    func parserController(_ inController: IMBParserController!, didLoad inParserMessenger: IMBParserMessenger!) {
        print("parserController didLoad: \(String(describing: type(of:inParserMessenger).identifier()))")
    }
}


extension ViewController : NSOutlineViewDataSource {
    // ノードが子を持つか？
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? IMBNode else { return false }
        return (node.subnodes as? [IMBNode])?.isEmpty == false
    }

    // 子の数
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let node = item as? IMBNode {
            return (node.subnodes as? [IMBNode])?.count ?? 0
        } else {
            return rootNodes.count
        }
    }

    // 子ノードを返す
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? IMBNode {
            return (node.subnodes as? [IMBNode])?[index] ?? IMBNode()
        } else {
            return rootNodes[index]
        }
    }
}

extension ViewController : NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? IMBNode else { return nil }

        let identifier = NSUserInterfaceItemIdentifier("NodeCell")
        let cell = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView ?? NSTableCellView()

        cell.textField?.stringValue = node.name ?? "(no name)"
        return cell
    }
}
