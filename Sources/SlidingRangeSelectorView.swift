//
//  SliderView.swift
//  UptechSlider
//
//  Created by Artem Mysik on 8/19/19.
//  Copyright © 2019 Uptech. All rights reserved.
//

import UIKit

protocol SlidingRangeSelectorViewDelegate: class {
    func sliderViewDidSelectRange(_ sliderView: SlidingRangeSelectorView, minIndex: Int, maxIndex: Int)
}

final class SlidingRangeSelectorView: UIView {

    // MARK: - Public Properties -

    weak var delegate: SlidingRangeSelectorViewDelegate?

    // MARK: - Private Properties -

    private var stackView: UIStackView!
    private var itemsViews = [ItemView]()
    private var rangeView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 34))

    private var firstSelectionView = SelectionView()
    private var secondSelectionView = SelectionView()

    private var maxSelectionView: SelectionView {
        return firstSelectionView.center.x >= secondSelectionView.center.x ? firstSelectionView : secondSelectionView
    }

    private var minSelectionView: SelectionView {
        return maxSelectionView == firstSelectionView ? secondSelectionView : firstSelectionView
    }

    private var convertedItemsFrames: [CGRect] {
        itemsViews.map { itemView in
            return self.convert(itemView.frame, from: stackView)
        }
    }

    fileprivate var currentProps: Props?

    // MARK: - Lifecycle -

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        rangeView.center.y = stackView.center.y
    }

    // MARK: - Private Methods -
    // MARK: Initial Setup

    private func setup() {
        setupStackView()
        setupSelectionViews()

        rangeView.backgroundColor = Constants.rangeViewColor
        insertSubview(rangeView, at: 0)
    }

    private func setupStackView() {
        stackView = UIStackView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.heightAnchor.constraint(equalToConstant: Constants.selectionViewHeight)
        ])
    }

    private func setupSelectionViews() {
        [minSelectionView, maxSelectionView].forEach { selectionView in
            addSubview(selectionView)
            selectionView.tapGesture.addTarget(self, action: #selector(SlidingRangeSelectorView.handleTapGesture(_:)))
            selectionView.panGesture.addTarget(self, action: #selector(SlidingRangeSelectorView.handlePanGesture(_:)))
            selectionView.alignMaskedView(to: stackView)
        }
    }

    private func updateRangeView() {
        let selectionViewsDistance = maxSelectionView.center.x - minSelectionView.center.x
        rangeView.frame.size.width = selectionViewsDistance
        rangeView.frame.origin.x = minSelectionView.center.x
    }

    private func findMinItemTo(centerX: CGFloat) -> ValueIndexWithSize? {
        return convertedItemsFrames
            .indices
            .map { ValueIndexWithSize(index: $0, frame: convertedItemsFrames[$0]) }
            .min(by: { abs($0.frame.midX - centerX) < abs($1.frame.midX - centerX) })
    }

    private func render(props: Props, animated: Bool) {
        setItems(props.values)
        selectItem(index: props.maxSelectedValueIndex, isMinimum: false, animated: animated)
        selectItem(index: props.minSelectedValueIndex, isMinimum: true, animated: animated)
        currentProps = props
    }

    private func setItems(_ items: [String]) {
        setupItemsViews(with: items)
        [minSelectionView, maxSelectionView].forEach { selectionView in
            let content = zip(itemsViews, items).map { (view: $0, title: $1) }
            selectionView.renderAndLayoutMask(for: content)
        }

        layoutIfNeeded()
    }

    private func setupItemsViews(with items: [String]) {
        if currentProps?.values.count != items.count {
            itemsViews.forEach { $0.removeFromSuperview() }
            itemsViews.removeAll()

            itemsViews = items.map { text in
                let itemView = ItemView()
                itemView.tapGesture.addTarget(self, action: #selector(SlidingRangeSelectorView.handleTapGesture(_:)))
                stackView.addArrangedSubview(itemView)
                itemView.text = text
                return itemView
            }
        } else {
            zip(itemsViews, items).forEach { itemView, text in
                itemView.text = text
            }
        }
    }

    private func selectItem(index: Int, isMinimum: Bool, animated: Bool = true) {
        let selectionView = isMinimum ? minSelectionView : maxSelectionView
        let frameForItem = convertedItemsFrames[index]
        let newSelectionViewWidth = SlidingRangeSelectorView.selectionViewWidth(for: itemsViews[index].text)

        let changeSelectionViewFrame: () -> Void = { [weak self] in
            selectionView.frame.size.width = newSelectionViewWidth
            selectionView.center.x = frameForItem.midX
            selectionView.center.y = frameForItem.midY
            self?.updateRangeView()
            self?.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.15, animations: changeSelectionViewFrame)
        } else {
            changeSelectionViewFrame()
        }
    }

    // MARK: - Public Methods -

    func set(values: [String], minSelectedValueIndex: Int, maxSelectedValueIndex: Int, animated: Bool) {
        if values.isEmpty {
            assertionFailure("Array with values can't be empty")
        } else if !values.indices.contains(minSelectedValueIndex) {
            assertionFailure("minSelectedValueIndex is out of values' bounds")
        } else if !values.indices.contains(maxSelectedValueIndex) {
            assertionFailure("maxSelectedValueIndex is out of values' bounds")
        }
        let props = Props(values: values, minSelectedValueIndex: minSelectedValueIndex, maxSelectedValueIndex: maxSelectedValueIndex)
        render(props: props, animated: animated)
    }
}

// MARK: - Gestures
extension SlidingRangeSelectorView {
    @objc private func handleTapGesture(_ tap: UITapGestureRecognizer) {
        guard let view = tap.view,
            let props = currentProps,
            let nearestItem = findMinItemTo(centerX: view.frame.midX) else {
                return
        }
        let oldMin = props.minSelectedValueIndex
        let oldMax = props.maxSelectedValueIndex
        let nearestValueIndex = nearestItem.index
        var newMinMaxIndices: (min: Int, max: Int) = (min: oldMin, max: oldMax)
        if nearestValueIndex == oldMin || nearestValueIndex == oldMax {
            let isMinimumWillMove = nearestValueIndex == oldMax
            selectItem(index: nearestValueIndex, isMinimum: isMinimumWillMove)
            newMinMaxIndices = (min: nearestValueIndex, max: nearestValueIndex)
        } else if nearestValueIndex < oldMin && nearestValueIndex < oldMax {
            selectItem(index: nearestValueIndex, isMinimum: true)
            newMinMaxIndices = (min: nearestValueIndex, max: oldMax)
        } else if nearestValueIndex > oldMin && nearestValueIndex < oldMax {
            selectItem(index: nearestValueIndex, isMinimum: true)
            selectItem(index: nearestValueIndex, isMinimum: false)
            newMinMaxIndices = (min: nearestValueIndex, max: nearestValueIndex)
        } else if nearestValueIndex > oldMin && nearestValueIndex > oldMax {
            selectItem(index: nearestValueIndex, isMinimum: false)
            newMinMaxIndices = (min: oldMin, max: nearestValueIndex)
        } else {
            assertionFailure("hmm some case is not handled")
        }

        currentProps?.minSelectedValueIndex = newMinMaxIndices.min
        currentProps?.maxSelectedValueIndex = newMinMaxIndices.max
        delegate?.sliderViewDidSelectRange(self, minIndex: newMinMaxIndices.min, maxIndex: newMinMaxIndices.max)
    }

    @objc private func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        guard let renderedProps = currentProps else {
            return
        }

        guard pan.state != .ended else {
            if let view = pan.view,
                let lastStoredItem = findMinItemTo(centerX: view.center.x) {
                selectItem(index: lastStoredItem.index, isMinimum: view == minSelectionView)
                let minIndex = view == minSelectionView ? lastStoredItem.index : renderedProps.minSelectedValueIndex
                let maxIndex = view == maxSelectionView ? lastStoredItem.index : renderedProps.maxSelectedValueIndex
                currentProps?.minSelectedValueIndex = minIndex
                currentProps?.maxSelectedValueIndex = maxIndex
                delegate?.sliderViewDidSelectRange(self, minIndex: minIndex, maxIndex: maxIndex)
            }
            pan.setTranslation(CGPoint.zero, in: self)
            return
        }

        if let view = pan.view {
            let translation = pan.translation(in: self)

            let minX = convertedItemsFrames[0].midX
            let maxX = convertedItemsFrames[renderedProps.values.count - 1].midX

            let changedX = view.center.x + translation.x

            if changedX >= minX && changedX <= maxX {
                view.center.x = changedX
            }

            if let nearestItem = findMinItemTo(centerX: view.center.x) {
                if findMinItemTo(centerX: minSelectionView.center.x) == findMinItemTo(centerX: maxSelectionView.center.x) {
                    currentProps?.minSelectedValueIndex = nearestItem.index
                    currentProps?.maxSelectedValueIndex = nearestItem.index
                } else if view == minSelectionView {
                    currentProps?.minSelectedValueIndex = nearestItem.index
                } else if view == maxSelectionView {
                    currentProps?.maxSelectedValueIndex = nearestItem.index
                }
            }

            let nearestFramesIndices = convertedItemsFrames
                .indices
                .sorted(by: { abs(convertedItemsFrames[$0].midX - view.center.x) < abs(convertedItemsFrames[$1].midX - view.center.x) })
                .prefix(2)
                .sorted(by: { convertedItemsFrames[$0].midX < convertedItemsFrames[$1].midX })
            if nearestFramesIndices.count == 2 {
                let leftNearestItemIndex = nearestFramesIndices[0]
                let rightNearestItemIndex = nearestFramesIndices[1]
                let leftNearestItemWidth = SlidingRangeSelectorView.selectionViewWidth(for: itemsViews[leftNearestItemIndex].text)
                let rightNearestItemWidth = SlidingRangeSelectorView.selectionViewWidth(for: itemsViews[rightNearestItemIndex].text)
                if leftNearestItemWidth == rightNearestItemWidth {
                    view.frame.size.width = leftNearestItemWidth
                } else {
                    let leftNearestItemMidX = convertedItemsFrames[leftNearestItemIndex].midX
                    let rightNearestItemMidX = convertedItemsFrames[rightNearestItemIndex].midX
                    let currentCoordinateCoef = (view.center.x - leftNearestItemMidX)/(rightNearestItemMidX - leftNearestItemMidX)
                    let selectionViewsWidthDiff = rightNearestItemWidth - leftNearestItemWidth
                    view.frame.size.width = currentCoordinateCoef * selectionViewsWidthDiff + leftNearestItemWidth
                }
            }

            updateRangeView()
        }

        layoutIfNeeded()
        pan.setTranslation(CGPoint.zero, in: self)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let pointForMinBlueView = minSelectionView.convert(point, from: self)
        let pointForMaxBlueView = maxSelectionView.convert(point, from: self)

        if minSelectionView.bounds.contains(pointForMinBlueView) {
            return minSelectionView
        } else if maxSelectionView.bounds.contains(pointForMaxBlueView) {
            return maxSelectionView
        }

        return super.hitTest(point, with: event)
    }

    // MARK: - Inner Declarations -

    fileprivate struct Props {
        let values: [String]
        fileprivate(set) var minSelectedValueIndex: Int
        fileprivate(set) var maxSelectedValueIndex: Int
    }
}

extension SlidingRangeSelectorView {
    fileprivate enum Constants {
        static let selectionViewColor = UIColor(red: 0/255, green: 158/255, blue: 152/255, alpha: 1.0)
        static let rangeViewColor = UIColor(white: 0.9, alpha: 1.0)
        static let margin: CGFloat = 0.0
        static let selectionViewMinWidth: CGFloat = 55
        static let selectionViewHeight: CGFloat = 55
    }

    private static func countLabelWidth(with text: String) -> CGFloat {
        let height: CGFloat = 25
        let attributedText = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15)])
        let drawingOptions: NSStringDrawingOptions = [NSStringDrawingOptions.usesLineFragmentOrigin,
                                                      NSStringDrawingOptions.usesFontLeading]
        let width = attributedText.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                             height: height),
                                                options: drawingOptions,
                                                context: nil).size.width

        return width
    }

    private static func selectionViewWidth(for text: String?) -> CGFloat {
        let labelWidth = countLabelWidth(with: text ?? String())
        let labelWidthWithMargins = labelWidth + 20
        let newSelectionViewWidth = labelWidthWithMargins < Constants.selectionViewMinWidth ? Constants.selectionViewMinWidth : labelWidthWithMargins
        return newSelectionViewWidth
    }
}

private struct ValueIndexWithSize: Equatable {
    let index: Int
    let frame: CGRect
}

// MARK: - Selection View
private class SelectionView: UIView {
    private let maskedView = MaskedView()
    let tapGesture = UITapGestureRecognizer()
    let panGesture = UIPanGestureRecognizer()

    init() {
        super.init(
            frame: CGRect(
                origin: .zero,
                size: .init(width: SlidingRangeSelectorView.Constants.selectionViewMinWidth,
                            height: SlidingRangeSelectorView.Constants.selectionViewHeight)
            )
        )
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = SlidingRangeSelectorView.Constants.selectionViewColor
        isUserInteractionEnabled = true
        layer.cornerRadius = 5
        layer.masksToBounds = true
        maskedView.backgroundColor = .clear
        maskedView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(maskedView)

        addGestureRecognizer(tapGesture)
        addGestureRecognizer(panGesture)
    }

    func alignMaskedView(to container: UIView) {
        NSLayoutConstraint.activate([
            maskedView.widthAnchor.constraint(equalTo: container.widthAnchor),
            maskedView.heightAnchor.constraint(equalTo: container.heightAnchor),
            maskedView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            maskedView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }

    func renderAndLayoutMask(for content: [(view: UIView, title: String)]) {
        maskedView.render(props: content)
    }
}

// MARK: - MaskedView
private final class MaskedView: UIView {
    typealias Props = [(view: UIView, title: String)]

    private var labels = [Label]()

    func render(props: Props) {
        if props.count != labels.count {
            self.subviews.forEach { $0.removeFromSuperview() }
            labels.removeAll()

            props.forEach { (view, title) in
                let label = Label()
                labels.append(label)
                label.set(active: true)
                label.text = title
                label.translatesAutoresizingMaskIntoConstraints = false
                addSubview(label)
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
                ])
            }
        } else {
            let titles = props.map { $0.title }
            zip(titles, labels).forEach { $1.text = $0 }
        }
    }
}

// MARK: - ItemView
private class ItemView: UIView {
    private let label: Label
    let tapGesture = UITapGestureRecognizer()

    var text: String? {
        set { label.text = newValue }
        get { return label.text }
    }

    override init(frame: CGRect) {
        label = Label()
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        label = Label()
        super.init(coder: coder)
        setup()
    }

    func set(active: Bool) {
        label.set(active: active)
    }

    private func setup() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        addGestureRecognizer(tapGesture)
    }
}

// MARK: - Label
private class Label: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func set(active: Bool) {
        textColor = active ? UIColor.white : UIColor.black
        font = UIFont.systemFont(ofSize: 15, weight: active ? .medium : .regular)
    }

    private func setup() {
        textAlignment = .center
        textColor = UIColor.black
        font = UIFont.systemFont(ofSize: 15, weight: .regular)
        text = String()
    }
}
