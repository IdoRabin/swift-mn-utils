//
//  MNTreeNodeTests.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

@testable import MNUtils
import XCTest
import Logging

fileprivate let dlog : Logger? = Logger(label: "MNTreeNodeTest") // ?.setting(verbose: false, testing: true)

class TestNode : MNTreeNode<String, String> {
    //
}

final class MNTreeNodeTest: XCTestCase {

    let root : TestNode? = TestNode(id: "1", value: "root")
    var child2a : TestNode? = TestNode(id: "2a", value: "child2a")

    override func setUpWithError() throws {
        dlog?.info("setUpWithError START")
        let child3b : TestNode? = TestNode(id: "3b", value: "child3b", parentIDString: "2b")
        let child2b : TestNode? = TestNode(id: "2b", value: "child2b", parent: root)
        let child3a : TestNode? = TestNode(id: "3a", value: "child3a", parentID: "2b")
        let child3x : TestNode? = TestNode(id: "3x", value: "child3x", parent: root)
        dlog?.info("""
        3b \( "\(child3b.descOrNil)" )
        2b \( "\(child2b.descOrNil)" )
        3a \( "\(child3a.descOrNil)" )
        3x \( "\(child3x.descOrNil)" )
""")
        
        //dlog?.info("== Setting parent for child2a: \((child2a?.id).descOrNil) parent: \((root?.id).descOrNil)")
        child2a?.setParent(root)
        dlog?.info("setUpWithError END: \(self.root!.treeDescription().descriptionLines)")
        //dlog?.info("setUpWithError END: \([child3b?.id, child2b?.id, child3a?.id, child3x?.id])")
    }

    override func tearDownWithError() throws {
        /*
        dlog?.info("tearDownWithError START")
        
        // let rootNodes = root?.allRootNodesForSelfOfHomogenousType ?? []
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        encoder.outputFormatting = .prettyPrinted
//        for isFlat in [false, true] {
//            print("encoding JSON:")
//            root!.config.isEncodeFlat = isFlat
//            // encoder.userInfo[root!.MNTN_is_flat_CodingUIKey] = isFlat
//            let coded = try encoder.encode(root)
//            let str = String(data: coded, encoding: .utf8) ?? "<encoding failed!>"
//            print("ONE JSON: \n" + str)
//        }
        
        // dlog?.info("tearDownWithError - will detach all")
        // child2a?.detachAll()
        
        for isFlat in [false] { // [false, true]
            let nodesCollection : MNTreeNodeCollection = [root!, child2a!].asMNTreeNodeCollection
            nodesCollection.isEncodeAllTreesFlat = isFlat
            nodesCollection.isEncodeCollectionInfo = true
            let coded = try encoder.encode(nodesCollection)
            for node in nodesCollection.nodes {
                dlog?.info("collection node: \(node.treeDescription().descriptionLines)")
            }
            
             let decoded = try decoder.decode(MNTreeNodeCollection.self, from: coded)
            print(" >> decoded trees \(isFlat ? "flat" : "tree" ) are equal? \(decoded == nodesCollection) <<")
                
        }

        dlog?.info("tearDownWithError END")
        // Finally?
//        for aroot in rootNodes {
//            aroot.detachAll(recursivelyDowntree: true) // remove all childrend and parent
//        }
         */
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
