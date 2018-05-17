//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

func testNil(arg: String? = ""){
    print(arg!.isEmpty)
}
testNil()
var nilStr: String? = ""
print(nilStr!.isEmpty)

let now = Date()
let formatter = DateFormatter()
formatter.dateStyle = .short
print(formatter.string(from: now))


let textField = UITextField()
let bounds = textField.layer.bounds
bounds.height

/*
 block
 */
