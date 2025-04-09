//
//  MNTreeNodeTests.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

@testable import MNUtils
import XCTest
import Logging

/*
// fileprivate let dlog : Logger? = Logger(label: "MNTreeNodeTest") // ?.setting(verbose: false, testing: true)
fileprivate let dlog : Logger? = Logger(label: "MNTreeNodeTest")


class TestNode : MNTreeNode<String, String> {
    //
}

final class MNTreeNodeTest: XCTestCase {

    let root : TestNode? = TestNode(id: "1", value: "root")
    var child4 : TestNode? = TestNode(id: "2d", value: "child4")

    override func setUpWithError() throws {
        dlog?.info("setUpWithError START")
        
        // Children
        let child2a : TestNode? = TestNode(id: "2a", value: "childA", parentIDString: "root")
        let child2b : TestNode? = TestNode(id: "2b", value: "childB", parentIDString: "root")
        let child2c : TestNode? = TestNode(id: "2c", value: "childC", parentIDString: "root")
        
        // Grandchildren
        
        let gchild2a1 : TestNode? = TestNode(id: "2a1", value: "gchild2a1", parentIDString: "2a")
        let gchild2a2 : TestNode? = TestNode(id: "2a2", value: "gchild2a2", parent: child2a)
        let child2a3 : TestNode? = TestNode(id: "2a3", value: "gchild2a3", parentID: "2a3")
        
        let child2c1 : TestNode? = TestNode(id: "2c1", value: "gchild2c1", parent: child2c)
        
        let ggchild2a2a : TestNode? = TestNode(id: "2a2a", value: "ggchild2a2a", parentID: "2a3")
        let ggchild2a2aX : TestNode? = TestNode(id: "2a2aX", value: "ggchild2a2aX", parentID: "2a2a")
        let ggchild2a2aY : TestNode? = TestNode(id: "2a2aY", value: "ggchild2a2aY", parentID: "2a2a")
        
        /*
        dlog?.info("""
        \n        3b \( "\(child3b.descOrNil)" )
        2b \( "\(child2b.descOrNil)" )
        3a \( "\(child3a.descOrNil)" )
        3x \( "\(child3x.descOrNil)" )
""")
        
        //dlog?.info("== Setting parent for child2a: \((child2a?.id).descOrNil) parent: \((root?.id).descOrNil)")
        dlog?.info("setUpWithError END: \(self.root!.treeDescription().descriptionLines)")
         */
        child4?.setParent(root)
        dlog?.info("setUpWithError END")
    }

    override func tearDownWithError() throws {
        
        dlog?.info("tearDownWithError START")

        
        // Finally?
        // dlog?.info("tearDownWithError - will detach all")
        for aroot in root?.allRootNodesForSelfOfHomogenousType ?? [] {
            aroot.detachAll(recursivelyDowntree: true) // remove all childrens and parent
        }
        
        MNTreeNodeMgr.shared.clear()
        dlog?.info("tearDownWithError END")
    }

    func testCreateFromJSON () throws {
        
    }
    
    func testMNTreeNodeEncoding () throws {
        // let rootNodes = root?.allRootNodesForSelfOfHomogenousType ?? []
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        encoder.outputFormatting = .prettyPrinted
        
        for isFlat in [false] { // [false, true]
            dlog?.info("= testMNTreeNodeEncoding with \(isFlat ? "flat" : "non-flat") tree = ")
            let nodesCollection : MNTreeNodeCollection = [root!, child4!].asMNTreeNodeCollection
            nodesCollection.isEncodeAllTreesFlat = isFlat
            nodesCollection.isEncodeCollectionInfo = true
            let encoded = try encoder.encode(nodesCollection)
            
            nodesCollection.logCollectionTree(ctx: "Encoded")
            
            /*
            let str = String(data: encoded, encoding: .utf8) ?? "<encoding failed!>"
            print(">> ONE JSON: \n" + str)
            */
            
            let decoded = try decoder.decode(MNTreeNodeCollection.self, from: encoded)
            print(" >> decoded trees [\(isFlat ? "flat" : "tree" )] are equal? \(decoded == nodesCollection ? "✅ true" : "❌ false") <<")
                
        }
    }

    func testMNTreeNode() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        let expectation = expectation(description: "wait for attemptReconstruction")
        
        dlog?.info("testMNTreeNode root: \(self.root.descOrNil) START")
        if root?.IS_SHOULD_AUTO_RECONSTRUCT == false {
            // Insteasd of auto - we will test an explicit reconstruction here:
            root?.attemptReconstruction(context: "testMNTreeNode after init", andRebuildQuickMap: true)
        }

        if root?.allChildren.count == 5 {
            expectation.fulfill()
        } else {
            // Noftify failed!
        }

        waitForExpectations(timeout: 0.05) {[self] err in
            dlog?.info("testMNTreeNode root: \(self.root.descOrNil) END")
        }
    }

    func testrecourseChildren() throws {
        for includeSelf in [false, true] {
            for method in MNTreeNodeRecursionType.allCases {
                
                // Test recourseChildren using the different methods, isIncludeSelf and checking is the stop condition block works
                var allChildrenCollected : [TestNode] = []
                let result = root?.recourseChildren({ node, depth in
                    allChildrenCollected.append(node as! TestNode)
                    return node
                }, method: method, stopTest: { node, depth, result in
                    return false
                }, includeSelf: includeSelf)
                
                dlog?.info("recourseChildren: \(method) includeSelf: \(includeSelf) count: \(result?.ids.description ?? "[]") allChildrenCollected: \(allChildrenCollected.ids.description)")
                XCTAssert(result?.count == (includeSelf ? 5 : 4), "recourseChildren failed")
                
//                + <TestNode id: "1" |root| 0x0000600000a4a080>
//                   ^ <MNTreeNode<String, String> id: "2a" |leaf| 0x0000600000a4a180>
//                   - <MNTreeNode<String, String> id: "2b" |node| 0x0000600000a4a200>
//                      ^ <MNTreeNode<String, String> id: "3a" |leaf| 0x0000600000a4a140>
//                   ^ <MNTreeNode<String, String> id: "3x" |leaf| 0x0000600000a40140>
                let incStr = (includeSelf ? "1," : "")
                switch method {
                case .breadthFirst:
                    XCTAssert(result?.ids.description ?? "[]" == "[\(incStr)2a,3x,2b,3a]", "recourseChildren failed")
                case .depthFirst:
                    XCTAssert(result?.ids.description ?? "[]" == "[\(incStr)2a,3x,2b,3a]", "recourseChildren failed")
                }
            }
        }
    }
        
    func testrecourseParents() throws {
//        for includeSelf in [false, true] {
//            for method in MNTreeNodeRecursionType.allCases {
////                var allParentsIterated : [TestNode] = []
////                
////                // Test recourseParents using the different methods, isIncludeSelf and checking is the stop condition block works
////                let parents = child2a?.recourseParents(recursionType: method, isIncludeSelf: includeSelf, stopCondition: { node in
////                    allParentsIterated.append(node)
////                    return node.value !== "root"
////                })
////                
////                dlog.info("recourseParents: \(method) includeSelf: \(includeSelf) count: \(parents?.count ?? 0) allParentsCollected: \(allParentsCollected.ids)")
////                XCTAssert(parents?.count == 2, "recourseParents failed")
//            }
//        }
    }
    func tesfilterChildrenDowntree() throws {
        // func filterChildrenDowntree(where block:(_ node:SelfType, _ depth:Int)->Bool, includeSelf:Bool, method:MNTreeNodeRecursionType)->[SelfType]
        for includeSelf in [false, true] {
            for method in MNTreeNodeRecursionType.allCases {
//                let filtered = root.filterChildrenDowntree(where:{
//            `     node, depth in
//                    return node.value != "child3a"
//                }, includeSelf: includeSelf, method: method)
//                // expect 4 children
//                dlog.info("filterChildrenDowntree: \(method) includeSelf: \(includeSelf) count: \(filtered.count) filtered: \(filtered.ids)")
//                XCTAssert(filtered.count == 4, "filterChildrenDowntree failed")
            }
        }
    }
    func testiterateChildrenDowntree() throws {
    }
    func testfirstChildDowntree() throws {
    }
    func testfilterParents() throws {
    }
    func testfirstParent() throws {
    }
    func testiterateParentNodes() throws {
    }
    func testallChildren() throws {
    }
    func testallChildrenCount() throws {
    }

    func testallParents() throws {
    }

    func testallChildrenByDepth() throws {
    }

    func testallParentsByDepth() throws {
    }

    func testRemoveChild() throws {
        XCTAssertTrue(root?.children.contains(child4!) ?? false, "child4 was not setUp in root parent correctly (check setUp) / root is nil")
        root?.removeChild(child4!)
        XCTAssertFalse(root?.children.contains(child4!) ?? true, "Child was not removed correctly / root is nil")
    }

    func testMoveToNewParent() throws {
        let newParent = TestNode(id: "5", value: "newParent")
        child4?.moveToNewParent(newParent)
        XCTAssertTrue(newParent.children.contains(child4!), "Child was not moved to new parent correctly")
        XCTAssertFalse(root?.children.contains(child4!) ?? false, "Child was not removed from old parent correctly")
    }

    func testIsChildOf() throws {
        XCTAssertTrue(child4?.isChildOf(node: root!) ?? false, "isChildOf failed")
        XCTAssertFalse(root?.isChildOf(node: child4!) ?? false, "isChildOf failed")
    }

    func testIsParentOf() throws {
        XCTAssertTrue(root?.isParentOf(node: child4!) ?? false, "isParentOf failed")
        XCTAssertFalse(child4?.isParentOf(node: root!) ?? false, "isParentOf failed")
    }

    deinit {
        dlog?.info("\(self).deinit()")
    }
//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
*/
