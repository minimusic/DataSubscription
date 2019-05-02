//
//  PublisherViewController.swift
//  Subscription
//
//  Created by Chad on 3/29/19.
//  Copyright © 2019 raizlabs. All rights reserved.
//

import UIKit

class PublisherViewController: UIViewController {
    /// View state can match data state, but doesn't need to
    public enum ViewState {
        case error(Error)
        case loading
        case loaded([DataModel])
    }

    var state: ViewState = .loading {
        didSet {
            tableView.backgroundView = nil
            switch state {
            case .error(_):
                break
            case .loading:
                tableView.backgroundView = LoadingProvider.getView()
            case .loaded(_):
                break
            }
            tableView.reloadData()
            // FIXME: error UI
        }
    }

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        return tableView
    }()
    private let container: DataContainer
    
    // MARK: - Init

    init(container: DataContainer) {
        self.container = container
        super.init(nibName: nil, bundle: nil)
        container.manager.subscribe(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Publisher"

        // Table
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
        tableView.delegate = self
        tableView.dataSource = self

        // Refresh button
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshData))
        navigationItem.rightBarButtonItem = refreshButton
    }

    @objc func refreshData() {
        container.manager.getData()
    }
}

// MARK: - UITableViewDelegate

extension PublisherViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}

// MARK: - UITableViewDelegate

extension PublisherViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch state {
        case .error(_):
            return 0
        case .loading:
            return 0
        case .loaded(let cells):
            return cells.count
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "DataCell")
        cell.translatesAutoresizingMaskIntoConstraints = false

        switch state {
        case .error(_):
            break
        case .loading:
            break
        case .loaded(let cells):
            let cellState = cells[indexPath.row]
            cell.textLabel?.text = cellState.title
            cell.backgroundColor = cellState.color
        }

        NSLayoutConstraint.activate([
            cell.contentView.heightAnchor.constraint(equalToConstant: 60),
            ])
        return cell
    }
}

/// Recieve data state publication and convert to local view state
/// setting the view state should refresh UI appropriately
extension PublisherViewController: SubscriberProtocol {
    public func publication(from publisher: AnyPublisher) {
        if let publisher = publisher as? Publisher<[DataModel]> {
            switch publisher.state {
            case .loaded(let newData):
                state = .loaded(newData)
            case .error(let theError):
                print("Error")
                state = .error(theError)
            case .loading:
                state = .loading
            case .unknown:
                break
            }
        } else {
            print("Recieved un-handled publication.")
        }
    }
}

// FIXME: move providers to separate file
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

class ErrorProvider {
    static func getView() -> UIView {
        // Overlay view can be resized by consumer to block content
        let errorView = UIView()
//        overlayView.isUserInteractionEnabled = false
//        let spinner = UIActivityIndicatorView(style: .whiteLarge)
//        spinner.color = UIColor.black.withAlphaComponent(0.4)
//        overlayView.addSubview(spinner)
//        spinner.translatesAutoresizingMaskIntoConstraints = false
//        spinner.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor).isActive = true
//        spinner.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor).isActive = true
//        spinner.startAnimating()
        return errorView
    }

}
