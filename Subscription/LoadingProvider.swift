//
//  LoadingProvider.swift
//  Subscription
//
//  Created by Chad on 5/2/19.
//  Copyright © 2019 raizlabs. All rights reserved.
//

import UIKit

class LoadingProvider {
    static func getView() -> UIView {
        // Overlay view can be resized by consumer to block content
        let overlayView = UIView()
        overlayView.isUserInteractionEnabled = false
        let spinner = UIActivityIndicatorView(style: .whiteLarge)
        spinner.color = UIColor.black.withAlphaComponent(0.4)
        overlayView.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor).isActive = true
        spinner.startAnimating()
        return overlayView
    }

}



public protocol ErrorViewDelegate: AnyObject {
    func errorViewWantsRefresh(_ errorView: ErrorView)
}

public class ErrorView: UIView {
    weak var delegate: ErrorViewDelegate?

    init() {
        // delegate set by parent after init
        super.init(frame: CGRect.zero)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        let label = UILabel()
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "ERROR"

        let button = UIButton(type: .custom)
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Reload", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            button.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 30),
            ])

    }

    @objc func buttonPressed() {
        delegate?.errorViewWantsRefresh(self)
    }
}
