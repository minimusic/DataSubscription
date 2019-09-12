//
//  ExplicitPubViewController.swift
//  Subscription
//
//  Created by Chad on 5/2/19.
//  Copyright © 2019 raizlabs. All rights reserved.
//

import UIKit

class ExplicitPubViewController: UIViewController {
    /// View state can match data state, but doesn't need to
    public enum ViewState {
        case error(Error)
        case loading
        case loaded([DataModel])
    }
    /// Update UI when view state changes
    private var state: ViewState = .loading

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        return tableView
    }()
    private let container: ServiceContainer

    // MARK: - Init

    init(container: ServiceContainer) {
        self.container = container
        super.init(nibName: nil, bundle: nil)
        // Because of the explicit protocol, we can't generalize subscription in the manager.
        // Must subscribe directly to the publisher
        container.expManager.publisher.subscribe(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Explicit Publisher"

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
        container.expManager.refreshIfNeeded()
    }

    func setViewState(_ newState: ViewState) {
        state = newState
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

    @objc func refreshData() {
        container.expManager.getData()
    }
}

// MARK: - UITableViewDelegate

extension ExplicitPubViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}

// MARK: - UITableViewDelegate

extension ExplicitPubViewController: UITableViewDataSource {
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

extension ExplicitPubViewController: ErrorViewDelegate {
    func errorViewWantsRefresh(_ errorView: ErrorView) {
        container.expManager.getData()
    }
}

// MARK: - SubscriberProtocol

/// Recieve data state publication and convert to local view state
/// setting the view state should refresh UI appropriately
extension ExplicitPubViewController: ExplicitSubscriber {
    func publication(from publisher: DataModelPublisher) {
        switch publisher.state {
        case .loaded(let newData):
            setViewState(.loaded(newData))
        case .error(let theError):
            setViewState(.error(theError))
        case .loading:
            // .loading(let oldData) would include any previous data, if available
            setViewState(.loading)
        case .unknown:
            //
            break
        }
    }
}
