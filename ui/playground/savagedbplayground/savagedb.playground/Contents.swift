//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

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

var views = [UIView]()
let container = UIScrollView()
for (i, label) in [1,2,3].enumerated() {
    print("\(i), \(label)")
}

func f(str:String){
    print(str)
}

let l = [1,2,3]
print("\u{2039}")


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









