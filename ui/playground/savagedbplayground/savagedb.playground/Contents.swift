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


let stamp = "2021-03-05"
let formatter = DateFormatter()
//formatter.locale = Locale(identifier: "en_US_POSIX")
formatter.dateFormat = "yyyy-MM-dd"
formatter.timeZone = TimeZone.current
//formatter.timeStyle = .short
//formatter.dateFormat = "MM/dd/yy HH:mm a"
let date = formatter.date(from: stamp)
//let date2 = formatter.date(from: "5/4/18 8:01 AM")
let now = formatter.string(from: Date())

let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd"
dateFormatter.timeZone = TimeZone.current
let nowString = dateFormatter.string(from: Date())
