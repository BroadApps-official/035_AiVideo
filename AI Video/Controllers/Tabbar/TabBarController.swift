import SnapKit
import UIKit

final class TabBarController: UITabBarController {
    static let shared = TabBarController()
    let videoView = UIView()
    let effectsView = UIView()
    let historyView = UIView()
    let settingsView = UIView()

    // MARK: - View Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()

        let videoVC = UINavigationController(
            rootViewController: HomeViewController()
        )
        let effectsVC = UINavigationController(
            rootViewController: AiEffectsViewController()
        )
        let historyVC = UINavigationController(
            rootViewController: HistoryViewController()
        )
        let settingsVC = UINavigationController(
            rootViewController: SettingsViewController()
        )

        videoVC.tabBarItem = UITabBarItem(
            title: L.aiVideo,
            image: UIImage(systemName: "sparkles"),
            tag: 0
        )

        effectsVC.tabBarItem = UITabBarItem(
            title: L.aiEffects,
            image: UIImage(systemName: "moon.stars.fill"),
            tag: 1
        )

        historyVC.tabBarItem = UITabBarItem(
            title: L.history,
            image: UIImage(systemName: "photo.tv"),
            tag: 2
        )

        settingsVC.tabBarItem = UITabBarItem(
            title: L.settings,
            image: UIImage(systemName: "gearshape.fill"),
            tag: 3
        )

        let viewControllers = [videoVC, effectsVC, historyVC, settingsVC]
        self.viewControllers = viewControllers

        setTabBarBackground()
        placeTabBarItemsInView()
        updateTabBar()
        adjustTabBarPosition()
        delegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustTabBarPosition()
    }
    
    private func adjustTabBarPosition() {
        guard UIDevice.isIphoneBelowX else { return }
        
        let height: CGFloat = 60
        var tabBarFrame = tabBar.frame
        tabBarFrame.size.height = height
        tabBarFrame.origin.y = view.frame.height - height - 10
        tabBar.frame = tabBarFrame
    }

    func updateTabBar() {
        tabBar.backgroundColor = .clear
        tabBar.tintColor = UIColor.labelsPrimary
        tabBar.unselectedItemTintColor = UIColor.labelsQuaternary
        tabBar.itemPositioning = .centered
    }

    private func setTabBarBackground() {
        let tabBarBackground = UIView(frame: tabBar.bounds)
        tabBarBackground.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        tabBarBackground.layer.cornerRadius = 20
        tabBarBackground.clipsToBounds = true

        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = tabBarBackground.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.layer.cornerRadius = 20
        blurEffectView.clipsToBounds = true

        tabBarBackground.addSubview(blurEffectView)

        var backgroundFrame = tabBar.bounds
        if UIDevice.isIpad {
            backgroundFrame.size.height = tabBar.bounds.height * 0.8
            backgroundFrame.origin.y = tabBar.bounds.origin.y
            backgroundFrame.size.width = tabBar.bounds.width * 0.85
        } else if UIDevice.isIphoneBelowX {
            backgroundFrame.size.height = tabBar.bounds.height
            backgroundFrame.origin.y = tabBar.bounds.origin.y + 7
            backgroundFrame.size.width = tabBar.bounds.width * 0.88
        } else if UIDevice.isIphoneXSeries {
            backgroundFrame.size.height = tabBar.bounds.height * 0.6
            backgroundFrame.origin.y = tabBar.bounds.origin.y - 5
            backgroundFrame.size.width = tabBar.bounds.width * 0.88
        } else if UIDevice.isIphoneProMax {
            backgroundFrame.size.height = tabBar.bounds.height * 0.6
            backgroundFrame.origin.y = tabBar.bounds.origin.y - 5
            backgroundFrame.size.width = tabBar.bounds.width * 0.85
        } else if UIDevice.isIphone15Pro {
            backgroundFrame.size.height = tabBar.bounds.height * 0.6
            backgroundFrame.origin.y = tabBar.bounds.origin.y - 5
            backgroundFrame.size.width = tabBar.bounds.width * 0.85
        } else {
            backgroundFrame.size.height = tabBar.bounds.height * 0.6
            backgroundFrame.origin.y = tabBar.bounds.origin.y - 5
        }

        backgroundFrame.origin.x = (tabBar.bounds.width - backgroundFrame.size.width) / 2

        tabBarBackground.frame = backgroundFrame
        blurEffectView.frame = backgroundFrame
        tabBarBackground.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tabBar.insertSubview(tabBarBackground, at: 0)
        tabBar.insertSubview(blurEffectView, at: 0)

        videoView.do { make in
            make.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            make.layer.cornerRadius = 12
            make.masksToBounds = true
        }

        effectsView.do { make in
            make.backgroundColor = .clear
            make.layer.cornerRadius = 12
            make.masksToBounds = true
        }

        historyView.do { make in
            make.backgroundColor = .clear
            make.layer.cornerRadius = 12
            make.masksToBounds = true
        }

        settingsView.do { make in
            make.backgroundColor = .clear
            make.layer.cornerRadius = 12
            make.masksToBounds = true
        }

        tabBarBackground.addSubviews(videoView, effectsView, historyView, settingsView)

        videoView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(8)
            make.width.equalToSuperview().dividedBy(4).offset(-10)
            if UIDevice.isIphoneBelowX {
                make.height.equalTo(44)
            }
        }

        effectsView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.equalTo(videoView.snp.trailing).offset(5)
            make.width.equalToSuperview().dividedBy(4).offset(-10)
            if UIDevice.isIphoneBelowX {
                make.height.equalTo(44)
            }
        }

        historyView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.equalTo(effectsView.snp.trailing).offset(10)
            make.width.equalToSuperview().dividedBy(4).offset(-5)
            if UIDevice.isIphoneBelowX {
                make.height.equalTo(44)
            }
        }

        settingsView.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview().inset(8)
            make.leading.equalTo(historyView.snp.trailing).offset(5)
            if UIDevice.isIphoneBelowX {
                make.height.equalTo(44)
            }
        }

        view.layoutIfNeeded()
        let leftViewWidth = (videoView.bounds.width / 4) - 8
        if UIDevice.isIphoneProMax {
            tabBar.itemSpacing = leftViewWidth + 10
        } else {
            tabBar.itemSpacing = leftViewWidth - 10
        }
    }

    private func placeTabBarItemsInView() {
        guard let tabBarItems = tabBar.items else { return }
        guard let tabBarBackground = tabBar.subviews.first(where: { $0 is UIView }) else { return }

        let createViewCenterX = tabBarBackground.frame.origin.x + tabBarBackground.frame.width * 0.15
        let videoViewCenterX = tabBarBackground.frame.origin.x + tabBarBackground.frame.width * 0.35
        let photoViewCenterX = tabBarBackground.frame.origin.x + tabBarBackground.frame.width * 0.55
        let settingsViewCenterX = tabBarBackground.frame.origin.x + tabBarBackground.frame.width * 0.75

        if tabBarItems.count > 0 {
            let createTabBarItem = tabBarItems[0]
            setTabBarItemCenter(createTabBarItem, centerX: createViewCenterX)
        }

        if tabBarItems.count > 1 {
            let videoTabBarItem = tabBarItems[1]
            setTabBarItemCenter(videoTabBarItem, centerX: videoViewCenterX)
        }

        if tabBarItems.count > 2 {
            let photoTabBarItem = tabBarItems[2]
            setTabBarItemCenter(photoTabBarItem, centerX: photoViewCenterX)
        }

        if tabBarItems.count > 3 {
            let settingsTabBarItem = tabBarItems[3]
            setTabBarItemCenter(settingsTabBarItem, centerX: settingsViewCenterX)
        }
    }

    private func setTabBarItemCenter(_ item: UITabBarItem, centerX: CGFloat) {
        if let itemView = tabBar.subviews.first(where: { $0 is UIControl && $0.frame.origin.x == centerX }) {
            itemView.center = CGPoint(x: centerX, y: itemView.center.y)
        }
    }
}

// MARK: - UITabBarControllerDelegate
extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        videoView.backgroundColor = .clear
        effectsView.backgroundColor = .clear
        historyView.backgroundColor = .clear
        settingsView.backgroundColor = .clear

        if viewController == viewControllers?[0] {
            videoView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        } else if viewController == viewControllers?[1] {
            effectsView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        } else if viewController == viewControllers?[2] {
            historyView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        } else if viewController == viewControllers?[3] {
            settingsView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        }
    }
}

// MARK: - UITabBarItem Extension for setting center position
extension UITabBarItem {
    func setCenterPosition(x: CGFloat) {
        guard let tabBarButton = value(forKey: "view") as? UIView else { return }
        tabBarButton.center.x = x
    }
}

// MARK: - ResizedForAspectFit
extension UIImage {
    func resizedForAspectFit(to size: CGSize) -> UIImage {
        let imageView = UIImageView(image: self)
        imageView.contentMode = .scaleToFill
        imageView.frame = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? self
    }
}
