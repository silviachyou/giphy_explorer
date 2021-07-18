import Foundation
import UIKit
import SnapKit
import Combine

private let thumbnailSize = 60

class GifCell: UICollectionViewCell {
  private let titleLabel = UILabel()

  private var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    return imageView
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.addSubview(imageView)
    contentView.addSubview(titleLabel)
    
    imageView.snp.makeConstraints { make in
      make.height.equalTo(thumbnailSize)
      make.width.equalTo(thumbnailSize)
      make.leading.equalToSuperview().offset(12)
      make.centerY.equalToSuperview()
    }
    titleLabel.snp.makeConstraints { make in
      make.leading.equalTo(imageView.snp.trailing).offset(16)
      make.trailing.equalToSuperview()
      make.centerY.equalToSuperview()
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    titleLabel.text = nil
    imageView.image = nil
  }
  
  func setTitle(_ title:String) {
    self.titleLabel.text = title
  }
  
  func setImage(_ image:UIImage) {
    self.imageView.image = image
  }
}
