//
//  SaveBundle.swift
//  assignment
//
//  Created by Wennong Cai on 26/5/19.
//  Copyright © 2019 Wennong Cai. All rights reserved.
//

// The solution of saving custom objects into UserDefaults is found on Internet
// Reference: http://ios-tutorial.com/how-to-save-array-of-custom-objects-to-nsuserdefaults/
// Reference: https://nshipster.com/nscoding/

import Foundation

// SaveBundle is a dataset that recorded all game attributes of one step. (that means, each step has a SaveBundle)

class SaveBundle: NSObject, NSCoding{
    static var key_FigureTypes = "saveKeyFigureTypes"
    static var key_FigureNames = "saveKeyFigureNames"
    static var key_WKCF = "saveKeyWhiteKingCastlingFlag"
    static var key_WQCF = "saveKeyWhiteQueenCastlingFlag"
    static var key_BKCF = "saveKeyBlackKingCastlingFlag"
    static var key_BQCF = "saveKeyBlackQueenCastlingFlag"
    static var key_enPassWhite = "saveKeyEnPassantOnWhite"
    static var key_enPassBlack = "saveKeyEnPassantOnBlack"
    static var key_currentSide = "saveKeyCurrentSide"
    
    var figureNames: [String] = Array(repeating: "", count: 64)
    var figureTypes: [String] = Array(repeating: "", count: 64)
    var whiteKingCastlingFlag: Bool
    var blackKingCastlingFlag: Bool
    var whiteQueenCastlingFlag: Bool
    var blackQueenCastlingFlag: Bool
    var enPassantFlagOnBlack: Int
    var enPassantFlagOnWhite: Int
    var currentSide: String
    
    init(boardCells: [[BoardCell]], wkcf: Bool, bkcf: Bool, wqcf: Bool, bqcf: Bool, enPassBlack: Int, enPassWhite: Int, current: String) {
        var counter = 0
        for x in 0...7 {
            for y in 0...7 {
                if boardCells[x][y].cellFigureName != nil {
                    figureTypes[counter] = boardCells[x][y].cellFigureType!
                    figureNames[counter] = boardCells[x][y].cellFigureName!
                }
                counter += 1
            }
        }
        whiteKingCastlingFlag = wkcf
        blackKingCastlingFlag = bkcf
        whiteQueenCastlingFlag = wqcf
        blackQueenCastlingFlag = bqcf
        enPassantFlagOnBlack = enPassBlack
        enPassantFlagOnWhite = enPassWhite
        currentSide = current
    }
    
    init(types: [String], names: [String], wkcf: Bool, bkcf: Bool, wqcf: Bool, bqcf: Bool, enPassBlack: Int, enPassWhite: Int, current: String) {
        figureTypes = types
        figureNames = names
        whiteKingCastlingFlag = wkcf
        blackKingCastlingFlag = bkcf
        whiteQueenCastlingFlag = wqcf
        blackQueenCastlingFlag = bqcf
        enPassantFlagOnBlack = enPassBlack
        enPassantFlagOnWhite = enPassWhite
        currentSide = current
    }
    
    
    // Use NSCoding to save Custom Object into the UserDefault
    // Ref: Solution found at https://nshipster.com/nscoding/
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.figureTypes, forKey: SaveBundle.key_FigureTypes);
        aCoder.encode(self.figureNames, forKey: SaveBundle.key_FigureNames);
        aCoder.encode(self.whiteKingCastlingFlag, forKey: SaveBundle.key_WKCF);
        aCoder.encode(self.blackKingCastlingFlag, forKey: SaveBundle.key_BKCF);
        aCoder.encode(self.whiteQueenCastlingFlag, forKey: SaveBundle.key_WQCF);
        aCoder.encode(self.blackQueenCastlingFlag, forKey: SaveBundle.key_BQCF);
        aCoder.encode(self.enPassantFlagOnBlack, forKey: SaveBundle.key_enPassBlack);
        aCoder.encode(self.enPassantFlagOnWhite, forKey: SaveBundle.key_enPassWhite);
        aCoder.encode(self.currentSide, forKey: SaveBundle.key_currentSide);
    }
    
    required convenience init?(coder decoder: NSCoder) {
        guard let figureTypes = decoder.decodeObject(forKey: SaveBundle.key_FigureTypes) as? [String],
            let figureNames = decoder.decodeObject(forKey: SaveBundle.key_FigureNames) as? [String],
            let currentSide = decoder.decodeObject(forKey: SaveBundle.key_currentSide) as? String
            else { return nil }
        
        self.init(
            types: figureTypes,
            names: figureNames,
            wkcf: decoder.decodeBool(forKey: SaveBundle.key_WKCF),
            bkcf: decoder.decodeBool(forKey: SaveBundle.key_BKCF),
            wqcf: decoder.decodeBool(forKey: SaveBundle.key_WQCF),
            bqcf: decoder.decodeBool(forKey: SaveBundle.key_BQCF),
            enPassBlack: decoder.decodeInteger(forKey: SaveBundle.key_enPassBlack),
            enPassWhite: decoder.decodeInteger(forKey: SaveBundle.key_enPassWhite),
            current: currentSide)
    }
}
