//
//  L-Tree.swift
//  Cloudition
//
//  Created by hisaki sato on 2023/10/23.
//

import Foundation

class LSystem {
    
    private(set) var symbol: String = ""
    private(set) var rule: [Character:String]
    
    /// L-Systemの初期状態とルールを設定
    /// - Parameters:
    ///   - initialSymbol: 初期状態
    ///   - rule: ルール
    init(initialSymbol: String, rule: [Character:String]) {
        self.symbol = initialSymbol
        self.rule = rule
    }
    
    /// ルールに沿って成長させる
    func grow() {
        var growTree: String = ""
        for c in self.symbol {
            if let replaceString = self.rule[c] {
                growTree += replaceString
            } else {
                growTree.append(c)
            }
        }
        self.symbol = growTree
    }
}
