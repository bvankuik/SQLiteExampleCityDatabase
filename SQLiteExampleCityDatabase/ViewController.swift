//
//  ViewController.swift
//  SQLiteExampleCityDatabase
//
//  Created by Bart van Kuik on 21/09/2018.
//  Copyright © 2018 DutchVirtual. All rights reserved.
//

import UIKit
import SQLite3

class ViewController: UIViewController {
    internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
    internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    private var db: OpaquePointer?
    private var statement: OpaquePointer?
    
    private let textField = UITextField()
    private let tableView = UITableView()
    
    private var cities: [String] = []
    
    @objc func textChanged() {
        guard let text = self.textField.text else {
            return
        }
        
        if text.isEmpty {
            self.cities = []
        } else {
            self.statement = self.prepareStatement()
            self.cities = self.bindAndExecute(statement: self.statement, searchString: text)
        }
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        self.db = self.openDatabase()
        
        self.textField.borderStyle = .roundedRect
        self.textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
//        self.textField.backgroundColor = UIColor.lightGray
        self.textField.placeholder = "Enter city"
        self.textField.font = UIFont.preferredFont(forTextStyle: .title3)
        
        self.tableView.dataSource = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        self.view.addSubview(stackView)
        
        stackView.addArrangedSubview(self.textField)
        stackView.addArrangedSubview(self.tableView)
        
        let guide = self.view.safeAreaLayoutGuide
        let constraints = [
            stackView.leadingAnchor.constraint(equalToSystemSpacingAfter: guide.leadingAnchor, multiplier: 1),
            stackView.topAnchor.constraint(equalToSystemSpacingBelow: guide.topAnchor, multiplier: 1),
            guide.trailingAnchor.constraint(equalToSystemSpacingAfter: stackView.trailingAnchor, multiplier: 1),
            guide.bottomAnchor.constraint(equalToSystemSpacingBelow: stackView.bottomAnchor, multiplier: 1)
        ]
        self.view.addConstraints(constraints)
    }
    
    deinit {
        self.finalize(statement: statement)
        if sqlite3_close(db) != SQLITE_OK {
            print("error closing database")
        }
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.textLabel?.text = self.cities[indexPath.row]
        return cell
    }
}

extension ViewController {
    private func openDatabase() -> OpaquePointer? {
        guard let path = Bundle.main.path(forResource: "cities", ofType: "sqlite") else {
            fatalError("No database file found")
        }
        print("Database exists: " + (FileManager.default.fileExists(atPath: path) ? "yes" : "no"))
        
        var fileSize : UInt64
        
        do {
            //return [FileAttributeKey : Any]
            let attr = try FileManager.default.attributesOfItem(atPath: path)
            fileSize = attr[FileAttributeKey.size] as! UInt64
            let dict = attr as NSDictionary
            fileSize = dict.fileSize()
        } catch {
            fatalError("Error getting file size: \(error)")
        }
        print("Database file size: " + String(describing: fileSize))
        
        var db: OpaquePointer?
        if sqlite3_open(path, &db) != SQLITE_OK {
            fatalError("error opening database")
        } else {
            print("database connection succeeded")
        }
        
        var statement: OpaquePointer?
        
        // Final check: list number of tables
        
        if sqlite3_prepare_v2(db, "SELECT count(*) as tablecount FROM sqlite_master WHERE type='table'", -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error preparing select: \(errmsg)")
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let tablecount = sqlite3_column_int64(statement, 0)
            print("tablecount = \(tablecount)")
        }
        
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error finalizing prepared statement: \(errmsg)")
        }
        return db
    }
    
    private func prepareStatement() -> OpaquePointer? {
        guard let db = self.db else {
            fatalError("No connection to database")
        }
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, "SELECT name FROM cities WHERE name like ?", -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("error preparing select: \(errmsg)")
        }
        
        return statement
    }
    
    private func bindAndExecute(statement: OpaquePointer?, searchString: String) -> [String] {
        var results: [String] = []
        
        if sqlite3_bind_text(statement, 1, searchString + "%", -1, SQLITE_TRANSIENT) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("failure binding: \(errmsg)")
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let cString = sqlite3_column_text(statement, 0) {
                let name = String(cString: cString)
                results.append(name)
            }
        }
        
        self.finalize(statement: statement)
        
        return results
    }
    
    private func finalize(statement: OpaquePointer?) {
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("error finalizing prepared statement: \(errmsg)")
        }
    }
}
