//
//  TableViewCell.swift
//  ForceRank
//
//  Created by Steven Tao on 5/10/15.
//  Copyright © 2015 roko. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    @IBOutlet var buttons: [UIButton]?
    @IBOutlet var labels: [UILabel]?
    @IBOutlet var textFields: [UITextField]?
    @IBOutlet var views: [UIView]?
    @IBOutlet var imagesViews: [UIImageView]?
    @IBOutlet var layoutConstraints: [NSLayoutConstraint]?
    @IBOutlet var switches: [UISwitch]?
    typealias ValueDidChangeAction = (TableViewCell) -> Void
    var valueDidChangeAction: ValueDidChangeAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

       
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            labels?.forEach{$0.alpha = 0.6}
        } else {
            labels?.forEach{$0.alpha = 1}
        }
    }
    
    
    @IBAction func valueDidChange(_ sender: Any) {
        valueDidChangeAction?(self)
    }
    


}
