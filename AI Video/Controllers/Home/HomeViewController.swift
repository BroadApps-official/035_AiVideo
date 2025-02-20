import ApphudSDK
import AVFoundation
import MobileCoreServices
import SnapKit
import UIKit
import UniformTypeIdentifiers

final class HomeViewController: UIViewController {
    private let purchaseManager = SubscriptionManager()

    private var selectedImage: UIImage?
    private var selectedImagePath: String?
    private let createButton = GeneralButton()

    private let aiVideoLabel = UILabel()
    private let stylesLabel = UILabel()
    private let imageLabel = UILabel()

    private var selectorView = SelectorView()
    private var selectedIndex: Int = 0

    private let styleSelectionView = StyleSelectionView()
    var selectedStyle: Int? = 0
    private let scrollView = UIScrollView()

    private let promptLabel = UILabel()
    private let promtView = TextView(type: .promt)

    private let selectImageView = SelectImageView()

    private var activeGenerationCount = 0
    private let maxGenerationCount = 2
    private var generationCount: Int {
        get { UserDefaults.standard.integer(forKey: "generationCount") }
        set { UserDefaults.standard.set(newValue, forKey: "generationCount") }
    }

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

        drawSelf()
        updateGenerateButtonState()
        updateViewVisibility()
        styleSelectionView.configureForCell(selectedIndex: 0)

        selectorView.delegate = self
        styleSelectionView.delegate = self
        selectImageView.delegate = self

        let textFields = [promtView.textField]
        let textViews = [promtView.textView]
        let textFieldsToMove = [promtView.textField]
        let textViewsToMove = [promtView.textView]

        KeyboardManager.shared.configureKeyboard(
            for: self,
            targetView: view,
            textFields: textFields,
            textViews: textViews,
            moveFor: textFieldsToMove,
            moveFor: textViewsToMove,
            with: .done
        )

        promtView.delegate = self
        loadLastGeneratedVideos()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateGenerateButtonState()
        updateGenerateButtonState()
    }

    private func moveHistory() {
        let generationVC = GenerationTimeViewController()
        let navigationController = UINavigationController(rootViewController: generationVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true, completion: nil)

        if let tabBarController = tabBarController {
            tabBarController.selectedIndex = 2

            if let tabBarController = tabBarController as? TabBarController {
                tabBarController.videoView.backgroundColor = UIColor.clear
                tabBarController.effectsView.backgroundColor = UIColor.clear
                tabBarController.historyView.backgroundColor = UIColor.bgTertiary
                tabBarController.settingsView.backgroundColor = UIColor.clear
            }
        }
    }

    private func drawSelf() {
        aiVideoLabel.do { make in
            make.text = L.aiVideo
            make.font = UIFont.CustomFont.largeTitleEmphasized
            make.textColor = UIColor.labelsPrimary
            make.textAlignment = .left
        }

        stylesLabel.do { make in
            make.text = L.stylesLabel
            make.font = UIFont.CustomFont.title2Emphasized
            make.textColor = UIColor.labelsSecondary
            make.textAlignment = .left
        }

        createButton.do { make in
            make.setTitle(to: L.createMasterpiece)
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCreateButton))
            make.addGestureRecognizer(tapGesture)
        }

        promptLabel.do { make in
            make.text = L.promptLabel
            make.font = UIFont.CustomFont.title2Emphasized
            make.textColor = UIColor.labelsSecondary
            make.textAlignment = .left
        }

        scrollView.addSubview(styleSelectionView)

        view.addSubviews(
            aiVideoLabel, selectorView, stylesLabel,
            scrollView, promptLabel, promtView,
            createButton, selectImageView
        )

        aiVideoLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(3)
            make.leading.equalToSuperview().offset(16)
        }

        selectorView.snp.makeConstraints { make in
            make.top.equalTo(aiVideoLabel.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(48)
        }

        stylesLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(selectorView.snp.bottom).offset(20)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(stylesLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(106)
        }

        styleSelectionView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.width.equalTo(368)
        }

        promptLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(scrollView.snp.bottom).offset(20)
        }

        promtView.snp.makeConstraints { make in
            make.top.equalTo(promptLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            if UIDevice.isIphoneBelowX {
                make.height.equalTo(130)
            } else {
                make.height.equalTo(160)
            }
        }

        selectImageView.snp.makeConstraints { make in
            make.top.equalTo(promptLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            if UIDevice.isIphoneBelowX {
                make.height.equalTo(130)
            } else {
                make.height.equalTo(160)
            }
        }

        createButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
    }

    private func updateViewVisibility() {
        if selectedIndex == 0 {
            promtView.isHidden = false
            selectImageView.isHidden = true
            promptLabel.text = L.promptLabel
        } else {
            promtView.isHidden = true
            selectImageView.isHidden = false
            promptLabel.text = L.imageLabel
        }
        stylesLabel.layoutIfNeeded()
    }

    @objc private func selectButtonTapped() {
        showImagePickerController(sourceType: .photoLibrary)
    }

    @objc private func photoButtonTapped() {
        showImagePickerController(sourceType: .camera)
    }

    private func setupTextView() {
        promtView.textView.delegate = self
    }

    private func updateGenerateButtonState() {
        let promptFilled = !promtView.textView.text.isEmpty
        let imageSelected = selectedImage != nil
        let isUnderLimit = activeGenerationCount < maxGenerationCount

        let isGenerationAllowed: Bool
        if selectedIndex == 0 {
            isGenerationAllowed = promptFilled && isUnderLimit
        } else {
            isGenerationAllowed = imageSelected && isUnderLimit
        }

        DispatchQueue.main.async {
            self.createButton.isEnabled = isGenerationAllowed
            self.createButton.isUserInteractionEnabled = isGenerationAllowed
            self.createButton.alpha = isGenerationAllowed ? 1.0 : 0.5
        }
    }

    private func getFinalPrompt() -> String {
        let baseText = promtView.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        let styleText: String
        switch selectedStyle {
        case 0: styleText = "Make animation"
        case 1: styleText = "Make animation in realistic style"
        case 2: styleText = "Make animation in Pixar style"
        case 3: styleText = "Make animation in Cyberpunk style"
        default: styleText = "Make animation"
        }

        return baseText.isEmpty ? styleText : "\(baseText). \(styleText)"
    }

    private func startGeneration() {
        let userId = Apphud.userID()
        let prompt = getFinalPrompt()
        let imagePath: String? = selectedImagePath
        let appBundle = Bundle.main.bundleIdentifier ?? "unknown"
        var generatedVideo = GeneratedVideo(id: "", prompt: prompt, isFinished: false)

        updateGenerateButtonState()

        Task {
            do {
                if activeGenerationCount >= maxGenerationCount {
                    while activeGenerationCount >= maxGenerationCount {
                        try await Task.sleep(nanoseconds: 1000000000)
                    }
                }
                activeGenerationCount += 1
                defer {
                    activeGenerationCount -= 1
                    updateGenerateButtonState()
                }

                let videoId = try await NetworkService.shared.createVideoTask(
                    imagePath: imagePath,
                    userId: userId,
                    appBundle: appBundle,
                    prompt: prompt
                )

                generatedVideo.id = videoId
                let imagePathToSave = imagePath ?? ""
                let videoData: [String: Any] = ["videoId": videoId, "prompt": prompt, "imagePath": imagePathToSave]

                saveLastGeneratedVideoData(videoData: videoData)
                CacheManager.shared.saveGeneratedVideoModel(generatedVideo)
                moveHistory()

                while true {
                    let videoStatus = try await NetworkService.shared.checkVideoTaskStatus(videoId: videoId)

                    if let isFinished = videoStatus["is_finished"] as? Bool, isFinished {
                        let videoUrl = try await NetworkService.shared.downloadVideoFile(videoId: videoId, prompt: prompt)
                        generatedVideo.isFinished = true
                        CacheManager.shared.saveGeneratedVideoModel(generatedVideo)
                        generationCount += 1

                        let resultVC = ResultViewController(model: generatedVideo, generationCount: generationCount, fromGeneration: true)
                        resultVC.delegate = self
                        let navigationController = UINavigationController(rootViewController: resultVC)
                        navigationController.modalPresentationStyle = .fullScreen
                        present(navigationController, animated: true, completion: nil)

                        break
                    }

                    if let isInvalid = videoStatus["is_invalid"] as? Bool, isInvalid {
                        DispatchQueue.main.async {
                            self.showErrorAlert()
                        }
                        break
                    }
                    try await Task.sleep(nanoseconds: 5 * 1000000000)
                }

            } catch {
                CacheManager.shared.deleteGeneratedVideoModel(generatedVideo)
                DispatchQueue.main.async {
                    self.showErrorAlert()
                }
            }
        }
    }

    private func saveLastGeneratedVideoData(videoData: [String: Any]) {
        var lastGeneratedVideos = getLastGeneratedVideos()
        if lastGeneratedVideos.count == 2 {
            lastGeneratedVideos.removeFirst()
        }
        lastGeneratedVideos.append(videoData)
        UserDefaults.standard.set(lastGeneratedVideos, forKey: "lastGeneratedVideoData")
    }

    private func getLastGeneratedVideos() -> [[String: Any]] {
        return UserDefaults.standard.array(forKey: "lastGeneratedVideoData") as? [[String: Any]] ?? []
    }

    private func loadLastGeneratedVideos() {
        let lastGeneratedVideos = getLastGeneratedVideos()

        if !lastGeneratedVideos.isEmpty {
            for videoData in lastGeneratedVideos {
                if let videoId = videoData["videoId"] as? String {
                    if CacheManager.shared.checkIfVideoFileExists(videoId: videoId) {
                    } else {
                        updateGenerateButtonState()
                        if activeGenerationCount >= maxGenerationCount {
                            Task {
                                while activeGenerationCount >= maxGenerationCount {
                                    try await Task.sleep(nanoseconds: 1 * 1000000000)
                                }
                            }
                        }
                        activeGenerationCount += 1
                        Task {
                            defer {
                                activeGenerationCount -= 1
                                updateGenerateButtonState()
                            }
                            do {
                                while true {
                                    let videoStatus = try await NetworkService.shared.checkVideoTaskStatus(videoId: videoId)

                                    if let isFinished = videoStatus["is_finished"] as? Bool, isFinished {
                                        let prompt = videoData["prompt"] as? String ?? ""
                                        let videoUrl = try await NetworkService.shared.downloadVideoFile(videoId: videoId, prompt: prompt)
                                        let generatedVideo = GeneratedVideo(id: videoId, prompt: prompt, isFinished: true)
                                        CacheManager.shared.saveGeneratedVideoModel(generatedVideo)
                                        generationCount += 1

                                        let resultVC = ResultViewController(model: generatedVideo, generationCount: generationCount, fromGeneration: false)
                                        let navigationController = UINavigationController(rootViewController: resultVC)
                                        navigationController.modalPresentationStyle = .fullScreen
                                        present(navigationController, animated: true, completion: nil)

                                        break
                                    } else if let isInvalid = videoStatus["is_invalid"] as? Bool, isInvalid {
                                        DispatchQueue.main.async {
                                            self.showErrorAlert()
                                        }
                                        break
                                    } else {
                                        try await Task.sleep(nanoseconds: 5 * 1000000000)
                                    }
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    self.showErrorAlert()
                                }
                            }
                        }
                    }
                }
            }
        } else {
        }
    }

    private func showErrorAlert() {
        if let videoData = UserDefaults.standard.dictionary(forKey: "lastGeneratedVideoData"),
           let videoId = videoData["videoId"] as? String {
            CacheManager.shared.deleteGeneratedVideoModel(withId: videoId)
        }

        UserDefaults.standard.removeObject(forKey: "lastGeneratedVideoData")
        UserDefaults.standard.synchronize()

        let alertController = UIAlertController(title: "Error", message: "Something went wrong. Try again.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        alertController.overrideUserInterfaceStyle = .dark
        present(alertController, animated: true, completion: nil)
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

    @objc private func openSubscription() {
        let subscriptionVC = SubscriptionViewController(isFromOnboarding: false, isExitShown: false)
        subscriptionVC.modalPresentationStyle = .fullScreen
        present(subscriptionVC, animated: true, completion: nil)
    }

    @objc private func openGeneration() {
        let generationVC = GenerationTimeViewController()
        let navigationController = UINavigationController(rootViewController: generationVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true, completion: nil)
    }

    @objc private func didTapCreateButton() {
        if purchaseManager.hasUnlockedPro {
            startGeneration()
        } else {
            openSubscription()
        }
    }
}

// MARK: - ResultVideoDelegate
extension HomeViewController: ResultViewControllerDelegate {
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

// MARK: - UIImagePickerControllerDelegate
extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        present(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            let resizedImage = resizeImageIfNeeded(image: selectedImage, maxWidth: 1260, maxHeight: 760)
            self.selectedImage = resizedImage
            selectImageView.addImage(image: selectedImage)

            if let imageURL = info[.imageURL] as? URL {
                selectedImagePath = imageURL.path
            } else {
                let tempDirectory = FileManager.default.temporaryDirectory
                let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")

                if let imageData = resizedImage.jpegData(compressionQuality: 1.0) {
                    do {
                        try imageData.write(to: tempFileURL)
                        selectedImagePath = tempFileURL.path
                    } catch {
                        print("Failed to save camera photo to temporary directory: \(error)")
                        selectedImagePath = nil
                    }
                }
            }
        }
        updateGenerateButtonState()
        picker.dismiss(animated: true)
    }

    func resizeImageIfNeeded(image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
        let originalWidth = image.size.width
        let originalHeight = image.size.height

        let widthRatio = maxWidth / originalWidth
        let heightRatio = maxHeight / originalHeight

        let scaleFactor = min(widthRatio, heightRatio)
        let newSize = CGSize(width: originalWidth * scaleFactor, height: originalHeight * scaleFactor)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - SelectImageViewDelegate
extension HomeViewController: SelectImageViewDelegate {
    func didTapAddPhoto(sender: SelectImageView) {
        if purchaseManager.hasUnlockedPro {
            showImageSelectionAlert()
        } else {
            openSubscription()
        }
    }

    private func showImageSelectionAlert() {
        let alert = UIAlertController(
            title: L.selectAction,
            message: L.selectActionSublabel,
            preferredStyle: .actionSheet
        )

        alert.overrideUserInterfaceStyle = .dark

        let selectFromGalleryAction = UIAlertAction(
            title: L.selectGallery,
            style: .default
        ) { _ in
            self.selectButtonTapped()
        }

        let takePhotoAction = UIAlertAction(
            title: L.takePphoto,
            style: .default
        ) { _ in
            self.photoButtonTapped()
        }

        let cancelAction = UIAlertAction(
            title: L.cancel,
            style: .cancel
        )

        alert.addAction(selectFromGalleryAction)
        alert.addAction(takePhotoAction)
        alert.addAction(cancelAction)

        if UIDevice.isIpad {
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = view
                popoverController.sourceRect = CGRect(
                    x: view.bounds.midX,
                    y: view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popoverController.permittedArrowDirections = []
            }
        }

        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension HomeViewController: SelectorDelegate {
    func didSelect(at index: Int) {
        selectedIndex = index
        updateGenerateButtonState()
        updateViewVisibility()
    }
}

// MARK: - GenreSelectionDelegate
extension HomeViewController: StyleSelectionDelegate {
    func didSelectStyle(selectedIndex: Int) {
        selectedStyle = selectedIndex
        updateGenerateButtonState()
    }
}

// MARK: - AppTextFieldDelegate
extension HomeViewController: TextViewDelegate {
    func didTapTextField(type: TextView.TextType) {
        updateGenerateButtonState()
    }
}

// MARK: - UITextViewDelegate
extension HomeViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateGenerateButtonState()
    }
}

extension Notification.Name {
    static let templatesUpdated = Notification.Name("templatesUpdated")
}

extension HomeViewController {
    @objc func keyboardWillShow(notification: NSNotification) {
        KeyboardManager.shared.keyboardWillShow(notification as Notification)
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        KeyboardManager.shared.keyboardWillHide(notification as Notification)
    }
}
