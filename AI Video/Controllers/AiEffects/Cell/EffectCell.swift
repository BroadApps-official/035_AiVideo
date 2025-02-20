import AVFoundation
import UIKit

final class EffectCell: UICollectionViewCell {
    static let identifier = "EffectCell"

    private var template: Template?

    private let videoView = UIView()
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private let label = UILabel()

    private var isVideoPlaying = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.bgTertiary
        contentView.layer.cornerRadius = 20
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        videoView.do { make in
            make.layer.cornerRadius = 20
            make.masksToBounds = true
        }

        label.do { make in
            make.font = UIFont.CustomFont.footnoteEmphasized
            make.textColor = UIColor.labelsPrimary
            make.textAlignment = .center
        }

        contentView.addSubviews(label, videoView)

        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(12)
        }

        videoView.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview().inset(8)
        }
    }

    func configure(with template: Template) {
        self.template = template
        label.text = template.effect

        if !isVideoPlaying {
            loadVideo(for: template)
        }
    }

    private func loadVideo(for template: Template) {
        CacheManager.shared.loadVideo(for: template) { [weak self] result in
            switch result {
            case let .success(videoURL):
                self?.playVideo(from: videoURL)
            case let .failure(error):
                print("Error loading video for template \(template.id): \(error.localizedDescription)")
            }
        }
    }

    private func playVideo(from url: URL) {
        guard !isVideoPlaying else {
            return
        }

        if player == nil {
            player = AVPlayer(url: url)
        }
        player?.volume = 0
        if playerLayer == nil {
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.videoGravity = .resizeAspectFill
            DispatchQueue.main.async { [weak self] in
                self?.playerLayer?.frame = self?.videoView.bounds ?? CGRect.zero
                if self?.playerLayer?.superlayer == nil {
                    self?.videoView.layer.addSublayer(self?.playerLayer ?? CALayer())
                }
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(restartVideo),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )

        player?.play()
    }

    @objc private func restartVideo() {
        player?.seek(to: .zero)
        player?.play()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.async { [weak self] in
            self?.playerLayer?.frame = self?.videoView.bounds ?? CGRect.zero
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
        isVideoPlaying = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
}
