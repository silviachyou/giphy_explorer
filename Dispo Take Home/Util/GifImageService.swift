import Foundation
import UIKit
import Combine

class GifImageService {
  static let sharedInstance = GifImageService()
  private var imageCache = NSCache<NSURL, UIImage>()
  
  func loadImage(url: URL) -> AnyPublisher<UIImage?, Never> {
    if let cachedImage = self.imageCache.object(forKey: url as NSURL) {
      return Just(cachedImage)
        .eraseToAnyPublisher()
    }
    return URLSession.shared.dataTaskPublisher(for: url)
      .tryMap { data, response -> UIImage? in
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
          throw URLError(.badServerResponse)
        }
        return UIImage(data:data)
      }
      .handleEvents(receiveOutput: {[weak self] image in
        guard let image = image else { return }
        self?.imageCache.setObject(image, forKey: url as NSURL)
      })
      .replaceError(with: nil)
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }
  
}
