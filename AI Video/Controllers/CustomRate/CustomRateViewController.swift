import UIKit

final class CustomRateViewController: UIViewController {
    // MARK: - Properties
    
    private let firstLabel = UILabel()
    private let secondLabel = UILabel()
    private let heartImageView = UIImageView()
    private let backButton = UIButton(type: .system)
    private let yesButton = GeneralButton()
    private let noButton = GeneralButton()

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
        
        let yesTapGesture = UITapGestureRecognizer(target: self, action: #selector(yesButtonTapped))
        yesButton.addGestureRecognizer(yesTapGesture)        
        let noTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCloseButton))
        noButton.addGestureRecognizer(noTapGesture)
    }

    private func drawSelf() {
        heartImageView.image = UIImage(named: "rate_heart_image")
        yesButton.setTitle(to: L.yes)
        noButton.setTitle(to: L.no)
        noButton.setBackgroundColor(UIColor.accentPrimaryAlpha)
        
        firstLabel.do { make in
            make.text = L.customRateLabel
            make.font = UIFont.CustomFont.title3Emphasized
            make.textColor = UIColor.labelsPrimary
            make.textAlignment = .center
        }
        
        secondLabel.do { make in
            make.text = L.customRateSecondLabel
            make.font = UIFont.CustomFont.footnoteRegular
            make.textColor = UIColor.labelsSecondary
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        view.addSubviews(firstLabel, secondLabel, heartImageView, noButton, yesButton)
    }

    private func configureConstraints() {
        heartImageView.snp.makeConstraints { make in
            if UIDevice.isIphoneBelowX {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(100)
            }
            make.centerX.equalToSuperview()
            make.size.equalTo(258)
        }
        
        firstLabel.snp.makeConstraints { make in
            make.top.equalTo(heartImageView.snp.bottom).offset(28)
            make.centerX.equalToSuperview()
            make.width.equalTo(280)
        }
        
        secondLabel.snp.makeConstraints { make in
            make.top.equalTo(firstLabel.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
            make.width.equalTo(280)
        }
        
        noButton.snp.makeConstraints { make in
            make.top.equalTo(secondLabel.snp.bottom).offset(28)
            make.leading.equalToSuperview().offset(32)
            make.height.equalTo(48)
            make.width.equalToSuperview().dividedBy(2).offset(-36)
        }
        
        yesButton.snp.makeConstraints { make in
            make.top.equalTo(secondLabel.snp.bottom).offset(28)
            make.trailing.equalToSuperview().inset(32)
            make.height.equalTo(48)
            make.width.equalToSuperview().dividedBy(2).offset(-36)
        }
    }

    private func setupBackButton() {
        backButton.do { make in
            make.setImage(UIImage(named: "close_button_icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
            make.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        }

        let backBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.rightBarButtonItem = backBarButtonItem
    }

    @objc private func didTapCloseButton() {
        dismiss(animated: true)
    }
    
    @objc private func yesButtonTapped() {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id6738688866?action=write-review") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            print("Unable to open App Store")
        }
        
        UserDefaults.standard.set(true, forKey: "customRate")
    }
}
