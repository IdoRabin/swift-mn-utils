//
//  File.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation

public class MNJSONEncoder : JSONEncoder {
    public override init() {
        super.init()
        self.isStringPreference = MNUtils.debug.IS_DEBUG
        
        // TODO: Find to make the encoder to round Floats too many digits for example: 7.000000000000000092
        // self.decimalEncodingStrategy = .string //outputs as string: "46.984765"
        // self .decimalEncodingStrategy = .precise //outputs as number: 46.984765
        // self .decimalEncodingStrategy = .lossy //current output like: 46.984765
    }
}
