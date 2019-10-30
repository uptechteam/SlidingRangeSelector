//
//  ViewController.swift
//  UptechSlider
//
//  Created by Artem Mysik on 8/19/19.
//  Copyright © 2019 Uptech. All rights reserved.
//

import UIKit

class PlainViewController: UIViewController {

    @IBOutlet private weak var sliderView: SlidingRangeSelectorView!
    
    var sliderModel = SliderModel(
        values: ["uptech", "1", "2", "3", "4", "5"],
        minSelectedValueIndex: 0,
        maxSelectedValueIndex: 3
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        sliderView.delegate = self
        sliderView.set(
            values: sliderModel.values,
            minSelectedValueIndex: sliderModel.minSelectedValueIndex,
            maxSelectedValueIndex: sliderModel.maxSelectedValueIndex,
            animated: false
        )
    }

}

extension PlainViewController: SlidingRangeSelectorViewDelegate {
    func sliderViewDidSelectRange(_ sliderView: SlidingRangeSelectorView, minIndex: Int, maxIndex: Int) {
        sliderModel.minSelectedValueIndex = minIndex
        sliderModel.maxSelectedValueIndex = maxIndex
    }
}
