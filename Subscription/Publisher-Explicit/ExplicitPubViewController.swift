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
    var state: ViewState = .loading {
        didSet {
            tableView.backgroundView = nil
            switch state {
            case .error:
                let errorView = ErrorView()
                errorView.delegate = self
                tableView.backgroundView = errorView
            case .loading:
                tableView.backgroundView = LoadingProvider.getView()
            case .loaded(_):
                break
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
        // Because of the explicit protocol, we can't generalize subscripotion in the manager
        container.expManager.publisher.subscribe(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Eplicit Publisher"

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
            state = .loaded(newData)
        case .error(let theError):
            state = .error(theError)
        case .loading:
            // .loading(let oldData) includes any previously loaded data, when available
            // but is un-used here
            state = .loading
        case .unknown:
            //
            break
        }
    }


}

//extension ExplicitPubViewController: SubscriberProtocol {
//    public func publication(from publisher: AnyPublisher) {
//        if let publisher = publisher as? Publisher<[DataModel]> {
//            switch publisher.state {
//            case .loaded(let newData):
//                state = .loaded(newData)
//            case .error(let theError):
//                state = .error(theError)
//            case .loading:
//                // .loading(let oldData) includes any previously loaded data, when available
//                // but is un-used here
//                state = .loading
//            case .unknown:
//                //
//                break
//            }
//        } else {
//            print("Recieved un-handled publication.")
//        }
//    }
//}
