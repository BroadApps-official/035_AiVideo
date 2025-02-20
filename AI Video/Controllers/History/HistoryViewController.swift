import SnapKit
import StoreKit
import UIKit

final class HistoryViewController: UIViewController {
    private var aiVideoModels: [GeneratedVideo] = []
    private var selectedAiVideoModel: GeneratedVideo?
    private let noVideoView = NoHistoryView()
    var currentVideoId: String?
    private let purchaseManager = SubscriptionManager()

    private let historyLabel = UILabel()
    private var selectorView = SelectorView()
    private var selectedIndex: Int = 0

    private var aiEffectsModels: [GeneratedVideoModel] = []
    private var selectedAiEffectsModel: GeneratedVideoModel?

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.bgPrimary
        collectionView.register(AiVideoCell.self, forCellWithReuseIdentifier: AiVideoCell.identifier)
        collectionView.register(AiEffectsCell.self, forCellWithReuseIdentifier: AiEffectsCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
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

        drawself()
        loadAllVideoModels()
        loadAiVideoModels()
        selectorView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAllVideoModels()
        loadAiVideoModels()
    }

    private func drawself() {
        selectorView.updateFirstLabel(L.aiVideo)
        selectorView.updateSecondLabel(L.aiEffectsLabel)

        historyLabel.do { make in
            make.text = L.history
            make.font = UIFont.CustomFont.largeTitleEmphasized
            make.textColor = UIColor.labelsPrimary
            make.textAlignment = .left
        }

        view.addSubviews(
            historyLabel, selectorView, noVideoView, collectionView
        )

        historyLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(3)
            make.leading.equalToSuperview().offset(16)
        }

        selectorView.snp.makeConstraints { make in
            make.top.equalTo(historyLabel.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(48)
        }

        noVideoView.snp.makeConstraints { make in
            make.top.equalTo(selectorView.snp.bottom).offset(80)
            make.centerX.equalToSuperview()
            make.width.equalTo(280)
            make.height.equalTo(115)
        }

        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(selectorView.snp.bottom).offset(20)
            make.bottom.equalToSuperview()
        }
    }

    private func loadAllVideoModels() {
        let allVideoModels = CacheManager.shared.loadGeneratedVideos()
        aiVideoModels = allVideoModels.reversed()
        collectionView.reloadData()
        updateViewForVideoModels()
    }

    private func loadAiVideoModels() {
        let allVideoModels = CacheManager.shared.loadAllVideoModels()
        aiEffectsModels = allVideoModels.sorted { model1, model2 -> Bool in
            model1.createdAt > model2.createdAt
        }
        collectionView.reloadData()
        updateViewForVideoModels()
    }

    private func updateViewForVideoModels() {
        if selectedIndex == 0 {
            if aiVideoModels.isEmpty {
                collectionView.isHidden = true
                noVideoView.isHidden = false
            } else {
                collectionView.isHidden = false
                noVideoView.isHidden = true
            }
        } else {
            if aiEffectsModels.isEmpty {
                collectionView.isHidden = true
                noVideoView.isHidden = false
            } else {
                collectionView.isHidden = false
                noVideoView.isHidden = true
            }
        }
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
extension HistoryViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedIndex == 0 ? aiVideoModels.count : aiEffectsModels.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if selectedIndex == 0 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AiVideoCell.identifier, for: indexPath) as? AiVideoCell else {
                return UICollectionViewCell()
            }
            let video = aiVideoModels[indexPath.item]
            cell.configure(with: video)
            let interaction = UIContextMenuInteraction(delegate: self)
            cell.backgroundColor = UIColor.bgPrimary
            cell.addInteraction(interaction)
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AiEffectsCell.identifier, for: indexPath) as? AiEffectsCell else {
                return UICollectionViewCell()
            }
            let effect = aiEffectsModels[indexPath.item]
            cell.configure(with: effect)
            let interaction = UIContextMenuInteraction(delegate: self)
            cell.backgroundColor = UIColor.bgPrimary
            cell.addInteraction(interaction)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedIndex == 0 {
            let selectedVideoModel = aiVideoModels[indexPath.item]
            guard selectedVideoModel.isFinished else {
                let alert = UIAlertController(
                    title: L.videoNotReady,
                    message: L.videoNotReadyMessage,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                alert.overrideUserInterfaceStyle = .dark
                present(alert, animated: true, completion: nil)
                return
            }

            let resultVC = ResultViewController(
                model: selectedVideoModel,
                generationCount: 0,
                fromGeneration: false
            )
            resultVC.delegate = self
            let navigationController = UINavigationController(rootViewController: resultVC)
            navigationController.modalPresentationStyle = .fullScreen
            present(navigationController, animated: true, completion: nil)
        } else {
            let selectedEffectModel = aiEffectsModels[indexPath.item]
            guard let isFinished = selectedEffectModel.isFinished, isFinished else {
                let alert = UIAlertController(
                    title: L.videoNotReady,
                    message: L.videoNotReadyMessage,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                alert.overrideUserInterfaceStyle = .dark
                present(alert, animated: true, completion: nil)
                return
            }

            let resultVC = AiEffectsResultViewController(
                model: selectedEffectModel,
                generationCount: 0,
                fromGeneration: false
            )
            resultVC.delegate = self
            let navigationController = UINavigationController(rootViewController: resultVC)
            navigationController.modalPresentationStyle = .fullScreen
            present(navigationController, animated: true, completion: nil)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width
        let height: CGFloat = (selectedIndex == 0) ? 260 : 302
        return CGSize(width: width, height: height)
    }
}

// MARK: - UIContextMenuInteractionDelegate
extension HistoryViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let convertedLocation = collectionView.convert(location, from: interaction.view)

        guard let indexPath = collectionView.indexPathForItem(at: convertedLocation) else {
            print("Failed to find indexPath for location: \(location)")
            return nil
        }

        var actions: [UIMenuElement] = []

        if selectedIndex == 0 {
            let selectedVideoModel = aiVideoModels[indexPath.item]
            currentVideoId = selectedVideoModel.id
            selectedAiVideoModel = selectedVideoModel

            let deleteAction = UIAction(title: L.delete, image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.deleteVideo()
            }

            actions.append(deleteAction)

            if selectedVideoModel.isFinished {
                let shareAction = UIAction(title: L.saveGallery, image: UIImage(systemName: "arrow.down.to.line")) { _ in
                    self.saveVideo()
                }

                let saveToFileAction = UIAction(title: L.saveFiles, image: UIImage(systemName: "folder.badge.plus")) { _ in
                    self.saveVideoToFiles()
                }

                actions.insert(contentsOf: [shareAction, saveToFileAction], at: 0)
            }
        } else {
            let selectedEffectModel = aiEffectsModels[indexPath.item]
            currentVideoId = selectedEffectModel.video
            selectedAiEffectsModel = selectedEffectModel

            let deleteAction = UIAction(title: L.delete, image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.deleteAiVideo()
            }

            actions.append(deleteAction)

            if selectedEffectModel.isFinished ?? false {
                let shareAction = UIAction(title: L.saveGallery, image: UIImage(systemName: "arrow.down.to.line")) { _ in
                    self.saveAiVideo(model: selectedEffectModel)
                }

                let saveToFileAction = UIAction(title: L.saveFiles, image: UIImage(systemName: "folder.badge.plus")) { _ in
                    self.saveAiVideoToFiles(model: selectedEffectModel)
                }

                actions.insert(contentsOf: [shareAction, saveToFileAction], at: 0)
            }
        }

        let menu = UIMenu(title: "", children: actions)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { _ in
            menu
        })
    }
}

// MARK: - Menu Functions
extension HistoryViewController {
    private func saveVideo() {
        guard let videoId = currentVideoId else {
            videoGalleryErrorAlert()
            return
        }

        let videoURL = CacheManager.shared.generatedVideosDirectory.appendingPathComponent("\(videoId).mp4")
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: videoURL.path) {
            let mediaSaver = VideoSaver()
            mediaSaver.saveVideoToGallery(videoURL: videoURL) { success in
                DispatchQueue.main.async {
                    if success {
                        self.videoGallerySuccessAlert()
                    } else {
                        self.videoGalleryErrorAlert()
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.videoGalleryErrorAlert()
            }
        }
    }

    private func saveVideoToFiles() {
        guard let videoID = currentVideoId else {
            videoFilesErrorAlert()
            return
        }

        let videoURL: URL
        if let selectedVideo = selectedAiVideoModel {
            videoURL = selectedVideo.cacheURL
        } else {
            videoFilesErrorAlert()
            return
        }

        if FileManager.default.fileExists(atPath: videoURL.path) {
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let copiedVideoURL = documentsDirectory.appendingPathComponent("\(videoID)_copy.mp4")

            do {
                if !fileManager.fileExists(atPath: copiedVideoURL.path) {
                    try fileManager.copyItem(at: videoURL, to: copiedVideoURL)
                }

                DispatchQueue.main.async {
                    let documentPicker = UIDocumentPickerViewController(forExporting: [copiedVideoURL])
                    documentPicker.delegate = self
                    documentPicker.overrideUserInterfaceStyle = .dark
                    self.present(documentPicker, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.videoFilesErrorAlert()
                }
            }
        } else {
            DispatchQueue.main.async {
                self.videoFilesErrorAlert()
            }
        }
    }

    private func deleteVideo() {
        let alert = UIAlertController(title: L.deleteVideo,
                                      message: L.deleteVideoMessage,
                                      preferredStyle: .actionSheet)

        let deleteAction = UIAlertAction(title: L.delete, style: .destructive) { _ in
            guard let videoModel = self.selectedAiVideoModel else { return }

            CacheManager.shared.deleteGeneratedVideoModel(withId: videoModel.id)

            if let index = self.aiVideoModels.firstIndex(where: { $0.id == videoModel.id }) {
                self.aiVideoModels.remove(at: index)
            } else {
                print("Video model with ID \(videoModel.id) not found in videoModels array.")
            }
            self.collectionView.reloadData()
            self.updateViewForVideoModels()
        }

        let cancelAction = UIAlertAction(title: L.cancel, style: .cancel) { _ in
            print("Video deletion was cancelled.")
        }

        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        alert.overrideUserInterfaceStyle = .dark
        present(alert, animated: true)
    }

    // MARK: - AiEffects
    private func saveAiVideo(model: GeneratedVideoModel) {
        guard let videoURL = CacheManager.shared.loadVideo(in: model) else {
            videoGalleryErrorAlert()
            return
        }

        let mediaSaver = VideoSaver()
        mediaSaver.saveVideoToGallery(videoURL: videoURL) { success in
            DispatchQueue.main.async {
                if success {
                    self.videoGallerySuccessAlert()
                } else {
                    self.videoGalleryErrorAlert()
                }
            }
        }
    }

    private func saveAiVideoToFiles(model: GeneratedVideoModel) {
        guard let videoURL = CacheManager.shared.loadVideo(in: model) else {
            videoFilesErrorAlert()
            return
        }

        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let copyURL = documentsDirectory.appendingPathComponent(videoURL.lastPathComponent)

        do {
            if fileManager.fileExists(atPath: copyURL.path) {
                try fileManager.removeItem(at: copyURL)
            }
            try fileManager.copyItem(at: videoURL, to: copyURL)

            DispatchQueue.main.async {
                let documentPicker = UIDocumentPickerViewController(forExporting: [copyURL])
                documentPicker.delegate = self
                documentPicker.overrideUserInterfaceStyle = .dark
                self.present(documentPicker, animated: true)
            }
        } catch {
            videoFilesErrorAlert()
        }
    }

    private func deleteAiVideo() {
        let alert = UIAlertController(title: L.deleteVideo,
                                      message: L.deleteVideoMessage,
                                      preferredStyle: .actionSheet)

        let deleteAction = UIAlertAction(title: L.delete, style: .destructive) { _ in
            guard let videoModel = self.selectedAiEffectsModel else { return }

            CacheManager.shared.deleteVideoModel(withId: videoModel.id)

            if let index = self.aiEffectsModels.firstIndex(where: { $0.id == videoModel.id }) {
                self.aiEffectsModels.remove(at: index)
            } else {
                print("Video model with ID \(videoModel.id) not found in videoModels array.")
            }
            self.collectionView.reloadData()
            self.updateViewForVideoModels()
        }

        let cancelAction = UIAlertAction(title: L.cancel, style: .cancel) { _ in
            print("Video deletion was cancelled.")
        }

        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        alert.overrideUserInterfaceStyle = .dark
        present(alert, animated: true)
    }
}

// MARK: - Alerts
extension HistoryViewController {
    private func videoGallerySuccessAlert() {
        let alert = UIAlertController(title: L.videoSavedGallery,
                                      message: nil,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        alert.overrideUserInterfaceStyle = .dark
        present(alert, animated: true)
    }

    private func videoGalleryErrorAlert() {
        let alert = UIAlertController(title: L.errorVideoGallery,
                                      message: L.errorVideoGalleryMessage,
                                      preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: L.cancel, style: .cancel)
        let tryAgainAction = UIAlertAction(title: L.tryAgain, style: .default) { _ in
            self.saveVideo()
        }

        alert.addAction(cancelAction)
        alert.addAction(tryAgainAction)
        alert.overrideUserInterfaceStyle = .dark
        present(alert, animated: true)
    }

    private func videoFilesSuccessAlert() {
        let alert = UIAlertController(title: L.videoSavedFiles,
                                      message: nil,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        alert.overrideUserInterfaceStyle = .dark
        present(alert, animated: true)
    }

    private func videoFilesErrorAlert() {
        let alert = UIAlertController(title: L.errorVideoFiles,
                                      message: L.errorVideoGalleryMessage,
                                      preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: L.cancel, style: .cancel)
        let tryAgainAction = UIAlertAction(title: L.tryAgain, style: .default) { _ in
            self.saveVideoToFiles()
        }

        alert.addAction(cancelAction)
        alert.addAction(tryAgainAction)
        alert.overrideUserInterfaceStyle = .dark
        present(alert, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension HistoryViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        videoFilesSuccessAlert()
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        videoFilesErrorAlert()
    }
}

// MARK: - SelectorDelegate
extension HistoryViewController: SelectorDelegate {
    func didSelect(at index: Int) {
        selectedIndex = index
        loadAllVideoModels()
        loadAiVideoModels()
        updateViewForVideoModels()
    }
}

// MARK: - AiEffectsResultViewControllerDelegate, ResultViewControllerDelegate
extension HistoryViewController: AiEffectsResultViewControllerDelegate, ResultViewControllerDelegate {
    func didTapCloseButton() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.openRateVC()
        }
    }

    private func openRateVC() {
        let rateVC = CustomRateViewController()
        let navigationController = UINavigationController(rootViewController: rateVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true, completion: nil)
    }
}
