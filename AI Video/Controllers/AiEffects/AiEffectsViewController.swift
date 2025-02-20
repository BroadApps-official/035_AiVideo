import SnapKit
import UIKit

final class AiEffectsViewController: UIViewController {
    private var videoModels: [GeneratedVideoModel] = []
    private var selectedVideoModel: GeneratedVideoModel?
    var currentVideoId: String?
    private let purchaseManager = SubscriptionManager()

    private let aiEffectsLabel = UILabel()
    private var selectedIndex: Int = 0

    private var templates: [Template] = []
    private lazy var actionProgress: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        return spinner
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: view.frame.width, height: view.frame.height)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(DoublesCell.self, forCellWithReuseIdentifier: DoublesCell.identifier)
        collectionView.register(EffectCell.self, forCellWithReuseIdentifier: EffectCell.identifier)
        collectionView.register(CreativesCell.self, forCellWithReuseIdentifier: CreativesCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

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

        if !purchaseManager.hasUnlockedPro {
            setupRightBarButton()
        }
        view.backgroundColor = UIColor.bgPrimary

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            templates = appDelegate.cachedTemplates
        }

        drawself()
        loadAllVideoModels()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .templatesUpdated, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAllVideoModels()
    }

    @objc private func updateTemplates(_ notification: Notification) {
        guard let updatedTemplates = notification.object as? [Template] else {
            print("Error: updatedTemplates is not of type [Template].")
            return
        }
        var newTemplates: [Template] = []
        for template in updatedTemplates {
            if !templates.contains(where: { $0.id == template.id }) {
                newTemplates.append(template)
            }
        }

        if !newTemplates.isEmpty {
            templates.append(contentsOf: newTemplates)
            let indexPaths = newTemplates.map { template in
                IndexPath(row: self.templates.firstIndex(where: { $0.id == template.id })!, section: 0)
            }
            collectionView.insertItems(at: indexPaths)
        } else {
            print("No new templates to add.")
        }

        toggleActionProgress()
    }

    private func toggleActionProgress() {
        if templates.isEmpty {
            actionProgress.startAnimating()
        } else {
            actionProgress.stopAnimating()
        }
    }

    private func drawself() {
        aiEffectsLabel.do { make in
            make.text = L.aiEffectsLabel
            make.font = UIFont.CustomFont.largeTitleEmphasized
            make.textColor = UIColor.labelsPrimary
            make.textAlignment = .left
        }

        view.addSubviews(
            aiEffectsLabel, collectionView, actionProgress
        )

        aiEffectsLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(3)
            make.leading.equalToSuperview().offset(16)
        }

        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(aiEffectsLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview()
        }

        actionProgress.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func loadAllVideoModels() {
        let allVideoModels = CacheManager.shared.loadAllVideoModels()

        videoModels = allVideoModels.sorted { model1, model2 -> Bool in
            model1.createdAt > model2.createdAt
        }
        collectionView.reloadData()
    }

    private func setupRightBarButton() {
        let proButtonView = createCustomProButton()
        let proBarButtonItem = UIBarButtonItem(customView: proButtonView)
        navigationItem.rightBarButtonItems = [proBarButtonItem]
    }

    private func createCustomProButton() -> UIView {
        let customButtonView = UIView()
        customButtonView.layer.cornerRadius = 8
        customButtonView.isUserInteractionEnabled = true
        customButtonView.clipsToBounds = true

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor(hex: "#5E2398").cgColor, UIColor(hex: "#9084BB").cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 113, height: 32)

        customButtonView.layer.insertSublayer(gradientLayer, at: 0)

        let iconImageView = UIImageView(image: UIImage(named: "set_proButton_icon"))
        iconImageView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = L.getPro.uppercased()
        label.textColor = UIColor.labelsPrimary
        label.font = UIFont.CustomFont.subheadlineEmphasized

        let stackView = UIStackView(arrangedSubviews: [label, iconImageView])
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center

        customButtonView.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        customButtonView.snp.makeConstraints { make in
            make.height.equalTo(32)
            make.width.equalTo(113)
        }

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(20)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(customProButtonTapped(_:)))
        customButtonView.addGestureRecognizer(tapGesture)

        return customButtonView
    }

    @objc private func customProButtonTapped(_ sender: UITapGestureRecognizer) {
        guard let buttonView = sender.view else { return }

        UIView.animate(withDuration: 0.05, animations: {
            buttonView.alpha = 0.5
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                buttonView.alpha = 1.0
            }
        }

        let subscriptionVC = SubscriptionViewController(isFromOnboarding: false, isExitShown: false)
        subscriptionVC.modalPresentationStyle = .fullScreen
        present(subscriptionVC, animated: true, completion: nil)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension AiEffectsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 2
        case 2: return 1
        default: return templates.filter { $0.effect != "Hug" && $0.effect != "Kiss" }.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DoublesCell.identifier, for: indexPath) as? DoublesCell else {
                return UICollectionViewCell()
            }
            return cell
        case 1:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EffectCell.identifier, for: indexPath) as? EffectCell else {
                return UICollectionViewCell()
            }
            let effect = indexPath.item == 0 ? "Hug" : "Kiss"
            if let model = templates.first(where: { $0.effect == effect }) {
                cell.configure(with: model)
            }
            return cell
        case 2:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CreativesCell.identifier, for: indexPath) as? CreativesCell else {
                return UICollectionViewCell()
            }
            return cell
        default:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EffectCell.identifier, for: indexPath) as? EffectCell else {
                return UICollectionViewCell()
            }
            let otherEffects = templates.filter { $0.effect != "Hug" && $0.effect != "Kiss" }
            let model = otherEffects[indexPath.item]
            cell.configure(with: model)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            let effect = indexPath.item == 0 ? "Hug" : "Kiss"
            if let model = templates.first(where: { $0.effect == effect }) {
                let viewController = OpenEffectsViewController(model: model, isDouble: true)
                viewController.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(viewController, animated: true)
            }

        case 3:
            let otherEffects = templates.filter { $0.effect != "Hug" && $0.effect != "Kiss" }
            let model = otherEffects[indexPath.item]
            let viewController = OpenEffectsViewController(model: model, isDouble: false)
            viewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewController, animated: true)

        default:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width / 2) - 6

        if indexPath.section == 0 || indexPath.section == 2 {
            return CGSize(width: width, height: 60)
        } else {
            return CGSize(width: width, height: width)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
}
