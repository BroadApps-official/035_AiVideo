import AVFoundation
import UIKit

final class AiEffectsCell: UICollectionViewCell {
    static let identifier = "AiEffectsCell"
    private var video: GeneratedVideoModel?

    private let label = UILabel()
    private let imageView = UIImageView()

    private let playButton = UIButton()
    let blurEffect = UIBlurEffect(style: .light)
    private let blurEffectView: UIVisualEffectView

    private let generationLabel = UILabel()
    private let generationActivityIndicator = UIActivityIndicatorView(style: .large)
    let imageViewBlurEffect = UIBlurEffect(style: .light)
    private let imageViewBlurEffectView: UIVisualEffectView

    override init(frame: CGRect) {
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        imageViewBlurEffectView = UIVisualEffectView(effect: imageViewBlurEffect)
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .white.withAlphaComponent(0.05)
        setupUI()
    }

    required init?(coder: NSCoder) {
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        imageViewBlurEffectView = UIVisualEffectView(effect: imageViewBlurEffect)
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        label.do { make in
            make.font = UIFont.CustomFont.footnoteEmphasized
            make.textAlignment = .center
            make.textColor = UIColor.labelsPrimary
        }

        imageView.do { make in
            make.layer.cornerRadius = 10
            make.masksToBounds = true
        }

        blurEffectView.do { make in
            make.layer.cornerRadius = 22
            make.layer.masksToBounds = true
        }

        imageViewBlurEffectView.do { make in
            make.layer.cornerRadius = 8
            make.layer.masksToBounds = true
        }

        playButton.do { make in
            make.layer.cornerRadius = 22
            make.setImage(UIImage(named: "main_play_icon"), for: .normal)
            make.tintColor = .white
            make.isUserInteractionEnabled = false
        }

        generationLabel.do { make in
            make.text = L.videoGenerationTimeCell
            make.font = UIFont.CustomFont.calloutRegular
            make.textAlignment = .center
            make.textColor = UIColor.labelsPrimary
            make.numberOfLines = 0
        }

        generationActivityIndicator.do { make in
            make.tintColor = .white.withAlphaComponent(0.7)
        }

        contentView.addSubview(imageView)
        contentView.addSubview(label)
        contentView.addSubview(blurEffectView)
        contentView.addSubview(playButton)

        contentView.addSubview(imageViewBlurEffectView)
        contentView.addSubview(generationLabel)
        contentView.addSubview(generationActivityIndicator)

        imageView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview().inset(8)
            make.top.equalToSuperview().offset(42)
        }

        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(12)
        }

        playButton.snp.makeConstraints { make in
            make.center.equalTo(imageView.snp.center)
            make.size.equalTo(44)
        }

        blurEffectView.snp.makeConstraints { make in
            make.edges.equalTo(playButton.snp.edges)
        }

        generationActivityIndicator.snp.makeConstraints { make in
            make.size.equalTo(33)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(123)
        }

        generationLabel.snp.makeConstraints { make in
            make.top.equalTo(generationActivityIndicator.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.equalTo(310)
        }

        imageViewBlurEffectView.snp.makeConstraints { make in
            make.edges.equalTo(imageView.snp.edges)
        }
    }

    func configure(with model: GeneratedVideoModel) {
        video = model
        label.text = model.name

        if model.isFinished == true {
            playButton.isHidden = false
            blurEffectView.isHidden = false
            generationActivityIndicator.isHidden = true
            generationLabel.isHidden = true
            imageViewBlurEffectView.isHidden = true
            generationActivityIndicator.stopAnimating()

            imageView.image = nil
            if let videoURL = CacheManager.shared.loadVideo(in: model) {
                generateThumbnail(from: videoURL)
            } else {
                print("Video loading error")
            }
        } else {
            playButton.isHidden = true
            blurEffectView.isHidden = true
            generationActivityIndicator.isHidden = false
            generationLabel.isHidden = false
            imageViewBlurEffectView.isHidden = false
            generationActivityIndicator.startAnimating()

            if let imagePath = model.imagePath, let imageURL = URL(string: imagePath) {
                if let image = UIImage(contentsOfFile: imageURL.path) {
                    imageView.image = image
                } else {
                    print("Failed to load image from path: \(imagePath)")
                }
            } else {
                print("No image path available")
            }
        }
    }

    private func generateThumbnail(from url: URL) {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 1, preferredTimescale: 600)

        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, result, error in
            if let error = error {
                print("Thumbnail generation error: \(error)")
                return
            }

            if result == .succeeded, let image = image {
                let uiImage = UIImage(cgImage: image)
                DispatchQueue.main.async {
                    self.imageView.image = uiImage
                }
            }
        }
    }
}
