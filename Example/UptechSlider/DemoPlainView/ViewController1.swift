//
//  ViewController.swift
//  UptechSlider
//
//  Created by Artem Mysik on 8/19/19.
//  Copyright © 2019 Uptech. All rights reserved.
//

import UIKit

class ViewController1: UIViewController {

    @IBOutlet private weak var sliderView: SliderView!
    
    var sliderModel = SliderModel(
        values: ["uptech", "23", "2000", "3", "68"],
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

extension ViewController1: SliderViewDelegate {
    func sliderViewDidSelectRange(_ sliderView: SliderView, minIndex: Int, maxIndex: Int) {
        sliderModel.minSelectedValueIndex = minIndex
        sliderModel.maxSelectedValueIndex = maxIndex
    }
}
