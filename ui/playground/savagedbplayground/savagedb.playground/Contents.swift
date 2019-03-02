//: Playground - noun: a place where people can play

import UIKit

var icons: DictionaryLiteral = ["JV Bus": "busIcon",
                                "Lodge Bus": "busIcon",
                                "NPS Vehicle": "busIcon",
                                "NPS Approved": "busIcon",
                                "NPS Contractor": "busIcon",
                                "Employee": "busIcon",
                                "Right of Way": "busIcon",
                                "Tek Camper": "busIcon",
                                "Bicycle": "busIcon",
                                "Propho": "busIcon",
                                "Accessibility": "busIcon",
                                "Hunting": "busIcon",
                                "Road lottery": "busIcon",
                                "Other": "busIcon"]



extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}


let stamp = "4/4/18, 8:26 AM"
let formatter = DateFormatter()
formatter.dateStyle = .short
formatter.timeStyle = .short
//formatter.dateFormat = "MM/dd/yy HH:mm a"
let date = formatter.date(from: stamp)
let date2 = formatter.date(from: "5/4/18 8:01 AM")
let now = Date()

now + 2


let dict = ["0": "a", "1": "b"]
var empty = [String: String]()
for key in dict.keys {
    empty[key] = dict[key]
}
for i in 0...3 {
    print(i)
}

var name = "something, "
print(name[..<name.index(name.endIndex, offsetBy: -2)])




