import Combine
import UIKit

class MainViewController: UIViewController {
  private var cancellables = Set<AnyCancellable>()
  private let searchTextChangedSubject = PassthroughSubject<String, Never>()
  private let viewAppear = PassthroughSubject<Void, Never>()
  private let cellTapped = PassthroughSubject<SearchResult, Never>()
  private var giphyResults = [SearchResult]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.titleView = searchBar
    
    let (
      loadResults,
      pushDetailView
    ) = mainViewModel(
      cellTapped: cellTapped.eraseToAnyPublisher(), // replace
      searchText: searchTextChangedSubject.eraseToAnyPublisher(),
      viewWillAppear: viewAppear.eraseToAnyPublisher()
    )
    
    loadResults
      .sink { [weak self] results in
        // load search results into data source
        self?.giphyResults = results
        self?.collectionView.reloadData()
      }
      .store(in: &cancellables)
    
    pushDetailView
      .sink { [weak self] result in
        // push detail view
        let detailViewController = DetailViewController(searchResult: result)
        self?.navigationController?.pushViewController(detailViewController, animated: true)
      }
      .store(in: &cancellables)
  }
  
  override func loadView() {
    view = UIView()
    view.backgroundColor = .systemBackground
    view.addSubview(collectionView)
    
    collectionView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    viewAppear.send()
    // A hack to publish empty query when there is no query
    if let searchText = self.searchBar.text {
      searchTextChangedSubject.send(searchText)
    }
  }
  
  private lazy var searchBar: UISearchBar = {
    let searchBar = UISearchBar()
    searchBar.placeholder = "search gifs..."
    searchBar.delegate = self
    return searchBar
  }()
  
  private var layout: UICollectionViewLayout {
    return UICollectionViewFlowLayout()
  }
  
  private lazy var collectionView: UICollectionView = {
    let collectionView = UICollectionView(
      frame: .zero,
      collectionViewLayout: layout
    )
    collectionView.backgroundColor = .clear
    collectionView.keyboardDismissMode = .onDrag
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(GifCell.self, forCellWithReuseIdentifier: "GifCell")
    return collectionView
  }()
}

extension MainViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.giphyResults.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GifCell", for: indexPath) as? GifCell else {
      fatalError()
    }
    let result = giphyResults[indexPath.row]
    cell.setTitle(result.title)
    GifImageService.sharedInstance.loadImage(url: result.gifUrl)
      .sink { image in
        guard let image = image else {
          return
        }
        cell.setImage(image)
      }
      .store(in: &cancellables)
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let result = giphyResults[indexPath.row]
    cellTapped.send(result)
  }
}

extension MainViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    return CGSize(width: view.frame.width, height: 60)
  }
}

// MARK: UISearchBarDelegate

extension MainViewController: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    searchTextChangedSubject.send(searchText)
  }
  
}
