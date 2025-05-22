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
        if let node = item as? IMBNode {
            // subnodesまたは objects のいずれかが非空、または populate されていなければ「展開可能」とみなす
            let subnodes = node.subnodes as? [IMBNode]
            let objects = node.objects as? [IMBObject]
            
            // populate済みなら中身を見て判断、未populateなら展開可能と仮定
            if node.isPopulated() {
                return (subnodes?.isEmpty == false) || (objects?.isEmpty == false)
            } else {
                return true // populate前なので展開可能とみなす
            }
        }
        return false
    }
    
    // 子の数
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let node = item as? IMBNode {
            let subnodes = node.subnodes as? [IMBNode] ?? []
            let objects = node.objects as? [IMBObject] ?? []
            return subnodes.count + objects.count
        } else {
            return rootNodes.count
        }
    }
    
    // 子ノードを返す
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? IMBNode {
            let subnodes = node.subnodes as? [IMBNode] ?? []
            if index < subnodes.count {
                return subnodes[index]
            }
            let objects = node.objects as? [IMBObject] ?? []
            return objects[index - subnodes.count]
        } else {
            return rootNodes[index]
        }
    }
}

extension ViewController : NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let columnId = tableColumn?.identifier.rawValue ?? ""

        if let node = item as? IMBNode {
            switch columnId {
            case "NodeColumn":
                let view = outlineView.makeView(withIdentifier: .init("NodeCell"), owner: self) as? NSTableCellView
                view?.textField?.stringValue = node.name ?? "(no name)"
                return view
            case "CountColumn":
                let view = outlineView.makeView(withIdentifier: .init("CountCell"), owner: self) as? NSTableCellView
                if let objects = node.objects as? [IMBObject], !objects.isEmpty {
                    view?.textField?.stringValue = "\(objects.count) photos"
                } else if let subnodes = node.subnodes as? [IMBNode] {
                    view?.textField?.stringValue = "\(subnodes.count) subnodes"
                } else {
                    view?.textField?.stringValue = "?"
                }
                return view
            case "IdentifierColumn":
                let view = outlineView.makeView(withIdentifier: .init("IdentifierCell"), owner: self) as? NSTableCellView
                view?.textField?.stringValue = node.identifier ?? "-"
                return view
            default:
                return nil
            }
        } else if let obj = item as? IMBObject {
            switch columnId {
            case "NodeColumn":
                let view = outlineView.makeView(withIdentifier: .init("NodeCell"), owner: self) as? NSTableCellView
                view?.textField?.stringValue = obj.name ?? "(photo)"
                return view
            case "CountColumn":
                let view = outlineView.makeView(withIdentifier: .init("CountCell"), owner: self) as? NSTableCellView
                view?.textField?.stringValue = "—"
                return view
            case "IdentifierColumn":
                let view = outlineView.makeView(withIdentifier: .init("IdentifierCell"), owner: self) as? NSTableCellView
                view?.textField?.stringValue = obj.identifier ?? "-"
                return view
            default:
                return nil
            }
        }

        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        guard let node = item as? IMBNode else { return true }

        // populate されていない場合はここで読み込む
        if !node.isPopulated() {
            librarycontroller?.populateNode(node) { (e) in
                print("⚠️ populate error while expanding: \(String(describing: e))")
            }

            // 展開対象ノードの subtree をリロード（objects.countを表示させるため）
            outlineView.reloadItem(node, reloadChildren: true)
        }

        return true // 展開を許可
    }
}
