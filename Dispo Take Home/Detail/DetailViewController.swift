import Combine
import UIKit

private let imageSize = 280

class DetailViewController: UIViewController {
  private var cancellables = Set<AnyCancellable>()
  private var gifId: String = ""
  private var gifUrl: URL?
  
  private var titleLabel = UILabel()
  private var ratingLabel = UILabel()
  private var sourceLabel = UILabel()
  
  private var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    return imageView
  }()
  
  private var linkButton : UIButton = {
    let button = UIButton()
    button.setTitle("Go to Giphy", for: .normal)
    button.addTarget(self, action: #selector(openBrowser), for: .touchUpInside)
    button.backgroundColor = UIColor.systemTeal
    button.layer.cornerRadius = 5
    return button
  }()
  
  init(searchResult: SearchResult) {
    super.init(nibName: nil, bundle: nil)
    gifId = searchResult.id
  }
  
  override func loadView() {
    view = UIView()
    view.backgroundColor = .systemBackground
    view.addSubview(imageView)
    view.addSubview(titleLabel)
    view.addSubview(ratingLabel)
    view.addSubview(sourceLabel)
    view.addSubview(linkButton)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupConstraints()
    
    let gifInfoPublisher = GifAPIClient.live.gifInfo(gifId)
    gifInfoPublisher
      .sink { [weak self] gifInfo in
        self?.titleLabel.text = gifInfo.text
        self?.ratingLabel.text = "Rating: \(gifInfo.rating.uppercased())"
        self?.sourceLabel.text = "Source: \(gifInfo.sourceTld.isEmpty ? "Unknown" : gifInfo.sourceTld)"
        self?.gifUrl = gifInfo.gifUrl
      }
      .store(in: &cancellables)
    
    let fetchImage = gifInfoPublisher
      .flatMap { gifInfo -> AnyPublisher<UIImage?, Never> in
        guard let url = gifInfo.gifUrl else {
          return Empty().eraseToAnyPublisher()
        }
        return GifImageService.sharedInstance.loadImage(url: url)
      }
    
    fetchImage
      .sink { [weak self] image in
        self?.imageView.image = image
      }.store(in: &cancellables)
  }
  
  private func setupConstraints() {
    imageView.snp.makeConstraints { make in
      make.width.equalTo(imageSize)
      make.height.equalTo(imageSize)
      make.centerX.equalToSuperview()
      make.top.equalToSuperview().offset(100)
    }
    titleLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(imageView.snp.bottom).offset(24)
    }
    ratingLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(titleLabel.snp.bottom).offset(12)
    }
    sourceLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(ratingLabel.snp.bottom).offset(12)
    }
    linkButton.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.width.equalToSuperview().multipliedBy(0.6)
      make.height.equalTo(40)
      make.top.equalTo(sourceLabel.snp.bottom).offset(24)
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @objc func openBrowser(sender: UIButton) {
    if let url = self.gifUrl {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
  }
}
