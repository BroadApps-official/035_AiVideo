import AVFoundation
import UIKit

final class AiVideoCell: UICollectionViewCell {
    static let identifier = "AiVideoCell"
    private var model: GeneratedVideo?

    private let imageView = UIImageView()

    private let playButton = UIButton()
    let blurEffect = UIBlurEffect(style: .light)
    private let blurEffectView: UIVisualEffectView

    private let generationLabel = UILabel()
    private let generationActivityIndicator = UIActivityIndicatorView(style: .large)

    override init(frame: CGRect) {
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.bgTertiary
        setupUI()
    }

    required init?(coder: NSCoder) {
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        imageView.do { make in
            make.layer.cornerRadius = 16
            make.masksToBounds = true
        }

        blurEffectView.do { make in
            make.layer.cornerRadius = 22
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
        contentView.addSubview(blurEffectView)
        contentView.addSubview(playButton)

        contentView.addSubview(generationLabel)
        contentView.addSubview(generationActivityIndicator)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
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
            make.top.equalToSuperview().offset(85)
        }

        generationLabel.snp.makeConstraints { make in
            make.top.equalTo(generationActivityIndicator.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.equalTo(310)
        }
    }

    func configure(with model: GeneratedVideo) {
        self.model = model

        if model.isFinished {
            playButton.isHidden = false
            blurEffectView.isHidden = false
            generationActivityIndicator.isHidden = true
            generationLabel.isHidden = true
            generationActivityIndicator.stopAnimating()

            imageView.image = nil
            let videoURL = model.cacheURL

            if FileManager.default.fileExists(atPath: videoURL.path) {
                generateThumbnail(from: videoURL)
                print("Video found: \(videoURL.path)")
            } else {
                print("Video not found: \(videoURL.path)")
            }
        } else {
            playButton.isHidden = true
            blurEffectView.isHidden = true
            generationActivityIndicator.isHidden = false
            generationLabel.isHidden = false
            generationActivityIndicator.startAnimating()

            imageView.image = UIImage(named: "ai_video_cell_placeholder")
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
