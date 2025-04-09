// MNTreeNode+Creation.swift
public extension MNTreeNodeProtocol {

    /// Will create a new tree heirarchy and append as children to the provided top node, or return the root node for the whole JSON
    /// NOTE: if the JSON root layer is an array or dictionary, there will be create an empty top root node.
    func createFromRawJSON(json:String, appendTo top:MNTreeNode<String, String>?)->MNResult<MNTreeNode<String, String>> {
        var depth = 0
        var index = 0
        let name = "roote"

        // let jsonTree : [String: String].deserializeFromJsonString<String>(string: json)
        return .failure(code: .misc_failed_parsing, reason: "MNTreeNode.\(Self.self) faild parsing the input JSON.")
        
    }
}
