//
//  SQLiteDatabase.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/22/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import Foundation
import SQLite3

class SQLiteDatabase {
    fileprivate let dbPointer: OpaquePointer?
    
    fileprivate var errorMessage: String {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            let errorMessage = String(cString: errorPointer)
            return errorMessage
        } else {
            return "No error message provided from sqlite."
        }
    }
    
    init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
    }
    
    deinit {
        sqlite3_close(dbPointer)
    }
    
    //MARK: Types
    enum SQLiteError: Error {
        case OpenDatabase(message: String)
        case Prepare(message: String)
        case Step(message: String)
        case Bind(message: String)
    }
    
    //MARK: Static methods
    static func open(path: String) throws -> SQLiteDatabase {
        var db: OpaquePointer? = nil
        // attempt to open the DB
        if sqlite3_open(path, &db) == SQLITE_OK {
            // return an instance of the sqlite db class
            return SQLiteDatabase(dbPointer: db)
        } else {
            // Otherwise, defer closing the database if the status code is anything but SQLITE_OK and throw an error
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            // Heandle the error message
            if let errorPointer = sqlite3_errmsg(db) {
                let message = String.init(cString: errorPointer)
                throw SQLiteError.OpenDatabase(message: message)
            } else {
                throw SQLiteError.OpenDatabase(message: "No error message provided from sqlite.")
            }
        }
    }
    
}


protocol SQLTable {
    static var createStatement: String { get }
}


extension SQLiteDatabase {
    
    func prepareStatement(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer? = nil
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.Prepare(message: errorMessage)
        }
        
        return statement
    }
    
    
    func createTable(table: SQLTable.Type) throws {
        // Try to prepare the statement
        let createTableStatement = try prepareStatement(sql: table.createStatement)
        // 2
        defer {
            sqlite3_finalize(createTableStatement)
        }
        // 3
        guard sqlite3_step(createTableStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        print("\(table) table created.")
    }
    
}



