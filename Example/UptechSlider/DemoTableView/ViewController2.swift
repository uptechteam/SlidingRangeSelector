//
//  ViewController2.swift
//  UptechSlider
//
//  Created by Artem Mysik on 14.10.2019.
//  Copyright © 2019 Uptech. All rights reserved.
//

import UIKit

class ViewController2: UIViewController, UITableViewDataSource, SliderTableViewCellDelegate {

    @IBOutlet private var tableView: UITableView!
    private var data = [SliderModel]()

    override func viewDidLoad() {
        super.viewDidLoad()

        let testData =  [
            SliderModel(
                values: ["1", "2", "3"],
                minSelectedValueIndex: 1,
                maxSelectedValueIndex: 2
            ),
            SliderModel(
                values: ["Demo app", "1", "2", "3"],
                minSelectedValueIndex: 0,
                maxSelectedValueIndex: 3
            ),
            SliderModel(
                values: ["uptech", "23", "2000", "3", "68"],
                minSelectedValueIndex: 2,
                maxSelectedValueIndex: 4
            ),
            SliderModel(
                values: ["1", "2", "3", "4", "5", "6", "7"],
                minSelectedValueIndex: 0,
                maxSelectedValueIndex: 5
            )
        ]

        data = Array<[SliderModel]>.init(repeating: testData, count: 10).flatMap{ $0 }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SliderTableViewCell
        cell.setup(with: data[indexPath.row])
        cell.delegate = self
        return cell
    }

    func sliderTableViewCellDidSelectRange(_ cell: SliderTableViewCell, minIndex: Int, maxIndex: Int) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        data[indexPath.row].maxSelectedValueIndex = maxIndex
        data[indexPath.row].minSelectedValueIndex = minIndex
    }

}
