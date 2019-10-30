//
//  SliderTableViewCell.swift
//  UptechSlider
//
//  Created by Artem Mysik on 14.10.2019.
//  Copyright © 2019 Uptech. All rights reserved.
//

import UIKit

protocol SliderTableViewCellDelegate: class {
    func sliderTableViewCellDidSelectRange(_ cell: SliderTableViewCell, minIndex: Int, maxIndex: Int)
}

class SliderTableViewCell: UITableViewCell {

    weak var delegate: SliderTableViewCellDelegate?

    @IBOutlet private var sliderView: SlidingRangeSelectorView!

    override func awakeFromNib() {
        super.awakeFromNib()
        sliderView.delegate = self
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func setup(with data: SliderModel) {
        DispatchQueue.main.async {
            self.sliderView.set(
                values: data.values,
                minSelectedValueIndex: data.minSelectedValueIndex,
                maxSelectedValueIndex: data.maxSelectedValueIndex,
                animated: false
            )
        }
    }

}

extension SliderTableViewCell: SlidingRangeSelectorViewDelegate {
    func sliderViewDidSelectRange(_ sliderView: SlidingRangeSelectorView, minIndex: Int, maxIndex: Int) {
        delegate?.sliderTableViewCellDidSelectRange(self, minIndex: minIndex, maxIndex: maxIndex)
    }
}
