//
//  OptionTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 4/6/2018.
//  Copyright © 2018 Quadrant. All rights reserved.
//

import UIKit

class OptionTableViewCell: UITableViewCell {

    // MARK: - Properties
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabelTop: NSLayoutConstraint!
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        hideIcon()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hideIcon()
        backgroundColor = .white
    }
    
    func showIcon(_ image: UIImage) {
        iconImageView.image = image
        iconImageView.isHidden = false
        titleLabelTop.constant = 8
    }
    
    func hideIcon() {
        iconImageView.isHidden = true
        titleLabelTop.constant = -11
    }
}
