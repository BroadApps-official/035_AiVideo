import AVKit
import UIKit

final class OnboardingPageViewController: UIViewController {
    // MARK: - Types

    enum Page {
        case animation, video, save, rate, notification
    }

    private let mainLabel = UILabel()
    private let subLabel = UILabel()
    private let imageView = UIImageView()
    private let shadowImageView = UIImageView()

    private let videoView = UIView()
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    // MARK: - Properties info

    private let page: Page

    // MARK: - Init

    init(page: Page) {
        self.page = page
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.bgPrimary

        switch page {
        case .animation: drawAnimation()
        case .video: drawVideo()
        case .save: drawSave()
        case .rate: drawRate()
        case .notification: drawNotification()
        }
    }

    // MARK: - Draw

    private func drawAnimation() {
        imageView.image = UIImage(named: "onb_animation_image")
        shadowImageView.image = UIImage(named: "onb_shadow_image")

        mainLabel.do { make in
            make.text = L.animationLabel
            make.textColor = UIColor.labelsPrimary
            make.font = UIFont.CustomFont.largeTitleEmphasized
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        view.addSubviews(imageView, shadowImageView, mainLabel)

        shadowImageView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height * (407.0 / 844.0))
        }

        imageView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height * (585.0 / 844.0))
        }

        mainLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }

    private func drawVideo() {
        imageView.image = UIImage(named: "onb_video_image")
        shadowImageView.image = UIImage(named: "onb_shadow_image")

        mainLabel.do { make in
            make.text = L.videoLabel
            make.textColor = UIColor.labelsPrimary
            make.font = UIFont.CustomFont.largeTitleEmphasized
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        view.addSubviews(imageView, shadowImageView, mainLabel)

        shadowImageView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height * (407.0 / 844.0))
        }

        imageView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height * (585.0 / 844.0))
        }

        mainLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }

    private func drawSave() {
        imageView.image = UIImage(named: "onb_save_image")
        shadowImageView.image = UIImage(named: "onb_shadow_image")

        mainLabel.do { make in
            make.text = L.saveLabel
            make.textColor = UIColor.labelsPrimary
            make.font = UIFont.CustomFont.largeTitleEmphasized
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        view.addSubviews(imageView, shadowImageView, mainLabel)

        shadowImageView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height * (407.0 / 844.0))
        }

        imageView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height * (585.0 / 844.0))
        }

        mainLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }

    private func drawRate() {
        imageView.image = UIImage(named: "onb_rate_image")
        shadowImageView.image = UIImage(named: "onb_shadow_image")

        mainLabel.do { make in
            make.text = L.rateLabel
            make.textColor = UIColor.labelsPrimary
            make.font = UIFont.CustomFont.largeTitleEmphasized
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        view.addSubviews(imageView, shadowImageView, mainLabel)

        shadowImageView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height * (407.0 / 844.0))
        }

        imageView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height * (585.0 / 844.0))
        }

        mainLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }

    private func drawNotification() {
        imageView.image = UIImage(named: "onb_notification_image")
        shadowImageView.image = UIImage(named: "onb_shadow_image")

        mainLabel.do { make in
            make.text = L.notificationLabel
            make.textColor = UIColor.labelsPrimary
            make.font = UIFont.CustomFont.largeTitleEmphasized
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        view.addSubviews(imageView, shadowImageView, mainLabel)

        shadowImageView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height * (407.0 / 844.0))
        }

        imageView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height * (585.0 / 844.0))
        }

        mainLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }
}
