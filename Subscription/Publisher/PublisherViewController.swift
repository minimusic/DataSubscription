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

    /// Update UI when viewState changes
    var state: ViewState = .loading {
        didSet {
            switch state {
            case .error:
                let errorView = ErrorView()
                errorView.delegate = self
                tableView.backgroundView = errorView
            case .loading:
                tableView.backgroundView = LoadingProvider.getView()
            case .loaded:
                tableView.backgroundView = nil
            }
            tableView.reloadData()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Try to clear any errors when user visits screen
        container.manager.refreshIfNeeded()
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
        case .error:
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
        case .error:
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

// MARK: - ErrorViewDelegate

extension PublisherViewController: ErrorViewDelegate {
    func errorViewWantsRefresh(_ errorView: ErrorView) {
        container.manager.getData()
    }
}

// MARK: - SubscriberProtocol

/// Recieve data state publication and convert to local view state
/// setting the view state should refresh UI appropriately
extension PublisherViewController: SubscriberProtocol {
    public func publication(from publisher: AnyPublisher) {
        if let publisher = publisher as? Publisher<[DataModel]> {
            switch publisher.state {
            case .loaded(let newData):
                state = .loaded(newData)
            case .error(let theError):
                state = .error(theError)
            case .loading:
                // .loading(let oldData) would include any previous data, if available
                state = .loading
            case .unknown:
                // Not handled in this app, but you may want to clear local cached state.
                // We have already initialized local viewstate with .loading
                break
            }
        } else {
            print("Recieved un-handled publication.")
        }
    }
}
