import Combine
import UIKit

func mainViewModel(
  cellTapped: AnyPublisher<SearchResult, Never>,
  searchText: AnyPublisher<String, Never>,
  viewWillAppear: AnyPublisher<Void, Never>
) -> (
  loadResults: AnyPublisher<[SearchResult], Never>,
  pushDetailView: AnyPublisher<SearchResult, Never>
) {
  let api = GifAPIClient.live
  
  let searchResults = searchText
    .combineLatest(viewWillAppear) { (query, _) -> AnyPublisher<[SearchResult], Never> in
      if query.isEmpty {
        return api.featuredGIFs()
      }
      return api.searchGIFs(query)
    }
    .switchToLatest()

  // show featured gifs when there is no search query, otherwise show search results
  let loadResults = searchResults.eraseToAnyPublisher()

  let pushDetailView = cellTapped
    .eraseToAnyPublisher()

  return (
    loadResults: loadResults,
    pushDetailView: pushDetailView
  )
}
