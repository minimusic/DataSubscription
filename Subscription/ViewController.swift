//
//  ViewController.swift
//  Subscription
//
//  Created by Chad on 10/9/18.
//  Copyright © 2018 raizlabs. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private let container: DataContainer
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .white
        return tableView
    }()

    init(container: DataContainer) {
        self.container = container
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Publisher Type"
        let backButton = UIBarButtonItem()
        backButton.title = "Type"
        self.navigationItem.backBarButtonItem = backButton
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

        tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let selectionIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectionIndexPath, animated: animated)
        }
    }

}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let pubVC = PublisherViewController(container: container)
            navigationController?.pushViewController(pubVC, animated: true)
        case 1:
            let expPubVC = ExplicitPubViewController(container: container)
            navigationController?.pushViewController(expPubVC, animated: true)
        case 2:
            let genPubVC = GenericPubViewController(container: container)
            navigationController?.pushViewController(genPubVC, animated: true)
        default:
            break
        }
    }
}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "MenuCell")
        cell.translatesAutoresizingMaskIntoConstraints = false
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Publisher"
        case 1:
            cell.textLabel?.text = "Explicit Publisher"
        case 2:
            cell.textLabel?.text = "Generic Publisher"
        default:
            cell.textLabel?.text = "Error"
        }
        cell.accessoryType = .disclosureIndicator
        NSLayoutConstraint.activate([
            cell.contentView.heightAnchor.constraint(equalToConstant: 100),
            ])
        return cell
    }
}

//extension ViewController: SubscriberProtocol {
//    //typealias dataType = Array<TestObject>
//
//    func publication(from publisher: NewPublisher<[TestObject]>) {
//        // handle data update
//        if let newData = publisher.data{
//            curData = newData
//        }
//        print("Subscriber Received: \(curData)")
////        let newData = publisher.data
//    }
//}
