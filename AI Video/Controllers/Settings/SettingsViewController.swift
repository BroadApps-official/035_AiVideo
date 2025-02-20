import UIKit
import ApphudSDK
import MessageUI
import StoreKit
import SafariServices
import WebKit

final class SettingsViewController: UIViewController {
    // MARK: - Properties
    
    private let settingsLabel = UILabel()
    private let supportLabel = UILabel()
    private let purchaseLabel = UILabel()
    private let infoLabel = UILabel()
    private let firstStackView = UIStackView()
    private let secondStackView = UIStackView()
    private let thirdStackView = UIStackView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - Init

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var upgradeView = UpgradeSettingsView(delegate: self)
    private lazy var notificationsView = NotificationSettingsView(delegate: self)
    private lazy var rateView = RateSettingsView(delegate: self)
    private lazy var contactView = ContactSettingsView(delegate: self)
    private lazy var privacyPolicyView = PrivacySettingsView(delegate: self)
    private lazy var usagePolicyView = UsageSettingsView(delegate: self)
    private lazy var casheView = CasheSettingsView(delegate: self)
    private lazy var restoreView = RestoreSettingsView(delegate: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        tabBarController?.tabBar.isTranslucent = true
        tabBarController?.tabBar.backgroundImage = UIImage()
        tabBarController?.tabBar.shadowImage = UIImage()
        
        tabBarItem.title = L.settings
        view.backgroundColor = UIColor.bgPrimary

        drawSelf()
        
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        configureConstraints()
    }

    private func drawSelf() {
        settingsLabel.do { make in
            make.text = L.settings
            make.font = UIFont.CustomFont.title1Emphasized
            make.textColor = UIColor.labelsPrimary
            make.textAlignment = .left
        }
        
        [supportLabel, purchaseLabel, infoLabel].forEach { label in
            label.do { make in
                make.font = UIFont.CustomFont.bodySemibold
                make.textColor = UIColor.labelsSecondary
                make.textAlignment = .left
            }
        }   
        
        supportLabel.text = L.supportUs
        purchaseLabel.text = L.purchasesActions
        infoLabel.text = L.infoLegal
        
        [firstStackView, secondStackView, thirdStackView].forEach { stackView in
            stackView.do { make in
                make.axis = .vertical
                make.spacing = 8
            }
        }

        firstStackView.addArrangedSubviews(
            [rateView]
        )        
        
        secondStackView.addArrangedSubviews(
            [upgradeView, notificationsView, casheView, restoreView]
        )
        
        thirdStackView.addArrangedSubviews(
            [contactView, privacyPolicyView, usagePolicyView]
        )

        scrollView.addSubviews(contentView)

        contentView.addSubviews(
            supportLabel, purchaseLabel, infoLabel,
            firstStackView, secondStackView, thirdStackView
        )

        view.addSubviews(settingsLabel, scrollView)
    }

    private func configureConstraints() {
        settingsLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(3)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(settingsLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
//            make.height.equalTo(scrollView.snp.height)
            make.bottom.equalTo(thirdStackView.snp.bottom).offset(16)
        }
        
        supportLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(22)
        }

        firstStackView.snp.makeConstraints { make in
            make.top.equalTo(supportLabel.snp.bottom).offset(14)
            make.trailing.leading.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        purchaseLabel.snp.makeConstraints { make in
            make.top.equalTo(firstStackView.snp.bottom).offset(28)
            make.trailing.leading.equalToSuperview().inset(16)
            make.height.equalTo(22)
        }
        
        secondStackView.snp.makeConstraints { make in
            make.top.equalTo(purchaseLabel.snp.bottom).offset(14)
            make.trailing.leading.equalToSuperview().inset(16)
            make.height.equalTo(200)
        }
        
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(secondStackView.snp.bottom).offset(28)
            make.trailing.leading.equalToSuperview().inset(16)
            make.height.equalTo(22)
        }
        
        thirdStackView.snp.makeConstraints { make in
            make.top.equalTo(infoLabel.snp.bottom).offset(14)
            make.trailing.leading.equalToSuperview().inset(16)
            make.height.equalTo(148)
        }

        [rateView, contactView, upgradeView, notificationsView,
         privacyPolicyView, usagePolicyView, casheView, restoreView].forEach { label in
            label.snp.makeConstraints { make in
                make.height.equalTo(44)
            }
        }
    }
}

// MARK: - CasheSettingsViewDelegate
extension SettingsViewController: CasheSettingsViewDelegate {
    func didTapCashe() {
        print("didTapCashe")
    }
}

// MARK: - RestoreSettingsViewDelegate
extension SettingsViewController: RestoreSettingsViewDelegate {
    func didTapRestore() {
        print("didTapRestore")
    }
}

// MARK: - NotificationSettingsViewViewDelegate
extension SettingsViewController: NotificationSettingsViewViewDelegate {
    func didTapNotificationView(switchValue: Bool) {
        print("notifications switchValue: \(switchValue)")
    }
}

// MARK: - UpgradeSettingsViewDelegate
extension SettingsViewController: UpgradeSettingsViewDelegate {
    func didTapUpgradeView() {
        let subscriptionVC = SubscriptionViewController(isFromOnboarding: false, isExitShown: false)
        subscriptionVC.modalPresentationStyle = .fullScreen
        present(subscriptionVC, animated: true, completion: nil)
    }
}

// MARK: - RateSettingsViewDelegate
extension SettingsViewController: RateSettingsViewDelegate {
    func didTapRateView() {
        DispatchQueue.main.async {
            guard let url = URL(string: "itms-apps://itunes.apple.com/app/id6738837329?action=write-review") else {
                return
            }

            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                print("Unable to open App Store")
            }
        }
    }
}

// MARK: - ContactSettingsViewDelegate
extension SettingsViewController: ContactSettingsViewDelegate {
    func didTapContactView() {
        guard MFMailComposeViewController.canSendMail() else {
            let alert = UIAlertController(title: "Error", message: "Mail services are not available", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            alert.overrideUserInterfaceStyle = .dark
            present(alert, animated: true, completion: nil)
            return
        }

        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.setToRecipients(["nhflatjscuba25687@gmail.com"])
        mailComposeVC.setSubject("Support Request")
        let userId = Apphud.userID()
        let messageBody = """
        Please describe your issue here.

        User ID: \(userId)
        """
        mailComposeVC.setMessageBody(messageBody, isHTML: false)
        mailComposeVC.mailComposeDelegate = self

        present(mailComposeVC, animated: true, completion: nil)
    }
}

// MARK: - PrivacySettingsViewDelegate
extension SettingsViewController: PrivacySettingsViewDelegate {
    func didTapPrivacyView() {
        guard let url = URL(string: "https://docs.google.com/document/d/1n9ZLN0s1H8i6jvgw5sbmDLCls-Qw4DC4Lhgbgi_LCoI/edit?usp=sharing") else {
            print("Invalid URL")
            return
        }
        
        let webView = WKWebView()
        webView.navigationDelegate = self as? WKNavigationDelegate
        webView.load(URLRequest(url: url))

        let webViewViewController = UIViewController()
        webViewViewController.view = webView

        self.present(webViewViewController, animated: true, completion: nil)
    }
}

// MARK: - UsageSettingsViewDelegate
extension SettingsViewController: UsageSettingsViewDelegate {
    func didTapUsageView() {
        guard let url = URL(string: "https://docs.google.com/document/d/1opVzCwn0Utc2weI3iHdhtl1R-Yp_GIkW8YkcRJ3kER4/edit?usp=sharing") else {
            print("Invalid URL")
            return
        }
        
        let webView = WKWebView()
        webView.navigationDelegate = self as? WKNavigationDelegate
        webView.load(URLRequest(url: url))

        let webViewViewController = UIViewController()
        webViewViewController.view = webView

        self.present(webViewViewController, animated: true, completion: nil)
    }
}

// MARK: - MFMailComposeViewControllerDelegate
extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - SKPaymentQueueDelegate
extension SettingsViewController: SKPaymentQueueDelegate {
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        let alert = UIAlertController(title: "Restore Purchases", message: "Your purchases have been restored.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.overrideUserInterfaceStyle = .dark
        self.present(alert, animated: true, completion: nil)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        let alert = UIAlertController(title: "Error", message: "There was an error restoring your purchases. Please try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.overrideUserInterfaceStyle = .dark
        self.present(alert, animated: true, completion: nil)
    }
}
