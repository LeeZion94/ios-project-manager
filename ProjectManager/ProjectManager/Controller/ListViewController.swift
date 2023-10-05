//
//  ListViewController.swift
//  ProjectManager
//
//  Created by Karen, Zion on 2023/10/03.
//

import UIKit

enum ListKind: String {
    case todo = "TODO"
    case doing = "DOING"
    case done = "DONE"
}

protocol ListViewControllerDelegate: AnyObject {
    func didTappedRightDoneButtonForUpdate(updateTask: Task)
}

final class ListViewController: UIViewController {
    enum Section {
        case main
    }
    
    weak var delegate: ListViewControllerDelegate?
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: listLayout)
        
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let listLayout: UICollectionViewCompositionalLayout = {
        return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            var listLayout = UICollectionLayoutListConfiguration(appearance: .grouped)
            
            listLayout.headerMode = .supplementary

            let section = NSCollectionLayoutSection.list(using: listLayout, layoutEnvironment: layoutEnvironment)
            
            section.interGroupSpacing = 10
            return section
        }
    }()
    
    private var diffableDataSource: UICollectionViewDiffableDataSource<Section, Task>?
    
    private let listKind: ListKind
    
    private var taskList: [Task] = []
    
    init(listKind: ListKind) {
        self.listKind = listKind
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setUpConstraints()
        setUpViewController()
        setUpDiffableDataSource()
        setUpDiffableDataSourceHeader()
        setUpDiffableDataSourceSanpShot()
    }
    
    private func configureUI() {
        view.addSubview(collectionView)
    }
    
    private func setUpConstraints() {
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setUpViewController() {
        view.backgroundColor = .systemBackground
    }
    
    private func convertFormattedDeadline(deadline: Double) -> String {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy. MM. dd."
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        
        return dateFormatter.string(from: Date(timeIntervalSince1970: deadline))
    }
}

// MARK: - Diffable DataSource
extension ListViewController {
    func setUpDiffableDataSourceSanpShot(taskList: [Task] = []) {
        var snapShot = NSDiffableDataSourceSnapshot<Section, Task>()
        
        self.taskList = taskList
        snapShot.appendSections([.main])
        snapShot.appendItems(taskList)
        snapShot.reloadSections([.main])
        diffableDataSource?.apply(snapShot)
    }
    
    private func setUpDiffableDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<ListCollectionViewCell, Task> { [weak self] cell, indexPath, task in
            guard let self = self else { return }
            let formattedDeadLine = self.convertFormattedDeadline(deadline: task.deadline)
            
            cell.setUpContents(title: task.title,
                               description: task.description,
                               deadline: formattedDeadLine)
        }
        
        diffableDataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, task in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration,
                                                                for: indexPath,
                                                                item: task)
        })
    }
    
    private func setUpDiffableDataSourceHeader() {
        let headerRegistration = UICollectionView.SupplementaryRegistration<ListCollectionHeaderView>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] headerView, elementKind, indexPath in
            guard let self = self else { return }
            
            headerView.setUpContents(title: self.listKind.rawValue, taskCount: "\(self.taskList.count)")
        }
        
        diffableDataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }
}

// MARK: - CollectionView Delegate
extension ListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let task = taskList[indexPath.row]
        let taskViewController = TaskViewController(task: task, mode: .update)
        let navigationController = UINavigationController(rootViewController: taskViewController)
        
        taskViewController.delegate = self
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

// MARK: - TaskViewController Delegate
extension ListViewController: TaskViewControllerDelegate {
    func didTappedRightDoneButton(task: Task) {
        delegate?.didTappedRightDoneButtonForUpdate(updateTask: task)
    }
}
