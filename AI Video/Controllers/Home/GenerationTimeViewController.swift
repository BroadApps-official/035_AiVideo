import Lottie
import UIKit

final class GenerationTimeViewController: UIViewController {
    // MARK: - Properties

    private let firstLabel = UILabel()
    private let secondLabel = UILabel()
    private let backButton = UIButton(type: .system)
    let animation = LottieAnimation.named("LottieAnimation")
    private var animationView = LottieAnimationView()

    // MARK: - Init

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = false

        setupBackButton()
        view.backgroundColor = UIColor.bgPrimary

        drawSelf()
        configureConstraints()
        animationView.play()
    }

    private func drawSelf() {
        firstLabel.do { make in
            make.text = L.creatingVideo
            make.font = UIFont.CustomFont.title3Emphasized
            make.textColor = UIColor.labelsPrimary
            make.textAlignment = .center
        }

        secondLabel.do { make in
            make.text = L.waitBit
            make.font = UIFont.CustomFont.footnoteRegular
            make.textColor = UIColor.labelsSecondary
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        animationView = LottieAnimationView(animation: animation)
        animationView.frame = view.frame
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.animationSpeed = 1.0

        view.addSubviews(firstLabel, secondLabel, animationView)
    }

    private func configureConstraints() {
        animationView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(UIScreen.main.bounds.height * (261.0 / 844.0))
            make.size.equalTo(280)
            make.centerX.equalToSuperview()
        }

        firstLabel.snp.makeConstraints { make in
            make.top.equalTo(animationView.snp.bottom)
            make.centerX.equalToSuperview()
        }

        secondLabel.snp.makeConstraints { make in
            make.top.equalTo(firstLabel.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
            make.width.equalTo(280)
        }

        var currentPercentage = 0
        let maxPercentage = 600

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            currentPercentage += 1
            if currentPercentage >= maxPercentage {
                timer.invalidate()
                self.didTapCloseButton()
            }
        }
    }

    private func setupBackButton() {
        backButton.do { make in
            make.setImage(UIImage(named: "close_button_icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
            make.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        }

        let backBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = backBarButtonItem
    }

    @objc private func didTapCloseButton() {
        dismiss(animated: true)
    }
}
