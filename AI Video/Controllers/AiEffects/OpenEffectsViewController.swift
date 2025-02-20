import SnapKit
import StoreKit
import ApphudSDK
import AVKit
import UIKit

final class OpenEffectsViewController: UIViewController {
    private let model: Template
    private let isDouble: Bool
    private var modelURL: String?
    
    private let playButton = UIButton()
    let blurEffect = UIBlurEffect(style: .light)
    private let blurEffectView: UIVisualEffectView
    
    private var playerViewController: AVPlayerViewController?
    private var player: AVPlayer?
    private var aspectRatio: CGFloat = 1 / 1
    private var isPlaying = false
    
    private let createButton = GeneralButton()
    private let selectImageView = SelectImageView()
    private let selectFirstDoubleImageView = SelectImageView()
    private let selectSecondDoubleImageView = SelectImageView()
    private var activeImageViewTag: Int?
    private let purchaseManager = SubscriptionManager()
    
    private var selectedImage: UIImage?
    private var selectedFirstDoubleImage: UIImage?
    private var selectedSecondDoubleImage: UIImage?
    private var selectedImagePath: String?
    private var selectedFirstDoubleImagePath: String?
    private var selectedSecondDoubleImagePath: String?
    var activeGenerationCount = 0
    let maxGenerationCount = 2

    private var generationCount: Int {
        get { UserDefaults.standard.integer(forKey: "generationCount") }
        set { UserDefaults.standard.set(newValue, forKey: "generationCount") }
    }

    private var isFirstGeneration: Bool = false

    init(model: Template, isDouble: Bool) {
        self.model = model
        self.isDouble = isDouble
        modelURL = model.preview
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        hidesBottomBarWhenPushed = true
        view.backgroundColor = UIColor.bgPrimary
        setupNavBar()
        drawself()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)

        let tapPlayGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPlayButton))
        playerViewController?.view.addGestureRecognizer(tapPlayGesture)
        
        selectImageView.delegate = self
        selectFirstDoubleImageView.delegate = self
        selectSecondDoubleImageView.delegate = self
        
        selectImageView.tag = 1
        selectFirstDoubleImageView.tag = 2
        selectSecondDoubleImageView.tag = 3
        
        if isDouble {
            let exampleVC = ExampleViewController()
            if let sheet = exampleVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
            present(exampleVC, animated: true)
        }
        
        let userDefaultsKey = "recentVideoGenerationIds"
        if let recentGenerationIds = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            if let lastGenerationId = recentGenerationIds.last {
                fetchSingleStatus(for: lastGenerationId)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNavBar() {
        title = model.effect
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "back_icon")?.withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(dismissViewController)
        )
    }

    private func drawself() {
        blurEffectView.do { make in
            make.layer.cornerRadius = 32
            make.layer.masksToBounds = true
        }
        
        playButton.do { make in
            make.layer.cornerRadius = 32
            make.setImage(UIImage(named: "main_play_icon"), for: .normal)
            make.tintColor = .white
            make.addTarget(self, action: #selector(didTapPlayButton), for: .touchUpInside)
        }

        let template = self.model

        CacheManager.shared.loadVideo(for: template) { [weak self] result in
            switch result {
            case let .success(videoURL):
                self?.loadAndPlayVideo(from: videoURL)
            case let .failure(error):
                print("Error loading video for template \(template.id): \(error.localizedDescription)")
            }
        }
    }

    private func loadAndPlayVideo(from url: URL) {
        let asset = AVAsset(url: url)
        let track = asset.tracks(withMediaType: .video).first

        if let naturalSize = track?.naturalSize {
            let width = naturalSize.width
            let height = naturalSize.height
            aspectRatio = width / height
        }

        player = AVPlayer(url: url)

        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        playerViewController?.showsPlaybackControls = false

        if let playerVC = playerViewController {
            addChild(playerVC)
            view.addSubview(playerVC.view)
            playerVC.videoGravity = .resizeAspectFill
            playerVC.view.layer.cornerRadius = 20
            playerVC.view.layer.masksToBounds = true
            playerVC.didMove(toParent: self)

            playerVC.view.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
                make.leading.trailing.equalToSuperview().inset(16)
                make.height.equalTo(view.snp.width)
            }
        }
        
        createButton.do { make in
            make.setTitle(to: L.createMasterpiece)
            if purchaseManager.hasUnlockedPro {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(startGeneration))
                make.addGestureRecognizer(tapGesture)
            } else {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openSubVC))
                make.addGestureRecognizer(tapGesture)
            }
        }
        
        selectFirstDoubleImageView.firstImageMode()
        selectSecondDoubleImageView.secondImageMode()

        view.addSubview(blurEffectView)
        view.addSubview(playButton)
        view.addSubview(createButton)
        
        if isDouble {
            view.addSubview(selectFirstDoubleImageView)
            view.addSubview(selectSecondDoubleImageView)
        } else {
            view.addSubview(selectImageView)
        }

        playButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(playerViewController?.view.snp.centerY ?? view.snp.centerY)
            make.size.equalTo(64)
        }

        blurEffectView.snp.makeConstraints { make in
            make.edges.equalTo(playButton.snp.edges)
        }
        
        createButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
        
        if isDouble {
            selectFirstDoubleImageView.snp.makeConstraints { make in
                make.top.equalTo(playerViewController?.view.snp.bottom ?? view.snp.bottom).offset(20)
                make.bottom.equalTo(createButton.snp.top).offset(-24)
                make.leading.equalToSuperview().offset(16)
                make.width.equalTo(playerViewController?.view.snp.width ?? view.snp.width).dividedBy(2).offset(-6)
            }
            
            selectSecondDoubleImageView.snp.makeConstraints { make in
                make.top.equalTo(playerViewController?.view.snp.bottom ?? view.snp.bottom).offset(20)
                make.bottom.equalTo(createButton.snp.top).offset(-24)
                make.trailing.equalToSuperview().inset(16)
                make.width.equalTo(playerViewController?.view.snp.width ?? view.snp.width).dividedBy(2).offset(-6)
            }
        } else {
            selectImageView.snp.makeConstraints { make in
                make.top.equalTo(playerViewController?.view.snp.bottom ?? view.snp.bottom).offset(20)
                make.leading.trailing.equalToSuperview().inset(20)
                make.bottom.equalTo(createButton.snp.top).offset(-24)
            }
        }
    }

    @objc private func dismissViewController() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func didTapPlayButton() {
        if isPlaying {
            player?.pause()
            playButton.isHidden = false
            blurEffectView.isHidden = false
            playButton.setImage(UIImage(named: "main_play_icon"), for: .normal)
        } else {
            player?.play()
            playButton.isHidden = true
            blurEffectView.isHidden = true
        }
        isPlaying.toggle()
    }

    @objc private func didFinishPlaying() {
        player?.seek(to: .zero)

        playButton.isHidden = false
        blurEffectView.isHidden = false
        playButton.setImage(UIImage(named: "main_play_icon"), for: .normal)
        isPlaying = false
    }

    @objc private func selectButtonTapped(sender: SelectImageView) {
        activeImageViewTag = sender.tag
        showImagePickerController(sourceType: .photoLibrary)
    }

    @objc private func photoButtonTapped(sender: SelectImageView) {
        activeImageViewTag = sender.tag
        showImagePickerController(sourceType: .camera)
    }
    
    //MARK: - Generation Work
    private func mergeImagesHorizontally(leftImage: UIImage, rightImage: UIImage) -> UIImage? {
        let newWidth = leftImage.size.width + rightImage.size.width
        let newHeight = max(leftImage.size.height, rightImage.size.height)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 0.0)
        
        leftImage.draw(in: CGRect(x: 0, y: 0, width: leftImage.size.width, height: newHeight))
        rightImage.draw(in: CGRect(x: leftImage.size.width, y: 0, width: rightImage.size.width, height: newHeight))
        
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return combinedImage
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
    
    @objc private func openSubVC() {
        let subscriptionVC = SubscriptionViewController(isFromOnboarding: false, isExitShown: true)
        subscriptionVC.modalPresentationStyle = .fullScreen
        present(subscriptionVC, animated: true, completion: nil)
    }
    
    @objc private func startGeneration() {
        if activeGenerationCount >= maxGenerationCount {
            let alert = UIAlertController(
                title: L.generationLimitReached,
                message: L.generationLimitReachedMessage,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            alert.overrideUserInterfaceStyle = .dark
            present(alert, animated: true, completion: nil)
            return
        }

        if generationCount == 0 {
            isFirstGeneration = true
            generationCount += 1
        } else {
            isFirstGeneration = false
            generationCount += 1
        }
        
        moveHistory()
        
        let selectedTemplateId = model.id
        let selectedTemplateEffect = model.effect
        
        var finalImage: UIImage?
        var finalImagePath: String?
        
        if isDouble {
            guard let firstImage = selectedFirstDoubleImage, let secondImage = selectedSecondDoubleImage else {
                print("Both images must be selected for double mode")
                return
            }
            
            if let mergedImage = mergeImagesHorizontally(leftImage: firstImage, rightImage: secondImage) {
                finalImage = mergedImage
                finalImagePath = saveImageToTemporaryDirectory(mergedImage)?.path
            } else {
                print("Failed to merge images")
                return
            }
        } else {
            guard let selectedImage = selectedImage, let selectedImagePath = selectedImagePath else {
                print("No image selected")
                return
            }
            finalImage = selectedImage
            finalImagePath = selectedImagePath
        }
        
        activeGenerationCount += 1
        
        guard let imagePath = finalImagePath else {
            print("Image path is not available")
            return
        }
        let userId = Apphud.userID()
        
        NetworkService.shared.generateEffect(
            templateId: "\(selectedTemplateId)",
            imageFilePath: imagePath,
            userId: userId,
            appId: Bundle.main.bundleIdentifier ?? "com.test.test"
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(data):
                    let generationId = data.data.generationId
                    self.saveGenerationIdToUserDefaults(generationId)
                    self.pollGenerationStatus(generationId: generationId, selectedTemplateEffect: selectedTemplateEffect, imagePath: imagePath)
                case let .failure(error):
                    if self.isFirstGeneration {
                        self.generationCount -= 1
                    }
                    self.generationIdError()
                }
            }
        }
    }

    private func saveGenerationIdToUserDefaults(_ generationId: String) {
        let userDefaultsKey = "recentVideoGenerationIds"
        var recentGenerationIds = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] ?? []

        recentGenerationIds.append(generationId)
        if recentGenerationIds.count > 2 {
            recentGenerationIds.removeFirst()
        }

        UserDefaults.standard.set(recentGenerationIds, forKey: userDefaultsKey)
    }

    private func fetchSingleStatus(for generationId: String) {
        NetworkService.shared.fetchEffectGenerationStatus(generationId: generationId) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(data):
                    if data.status == "error" {
                        self.checkGenerationStatus()
                    } else if data.status == "finished" {
                        let allVideoModels = CacheManager.shared.loadAllVideoModels()
                        if let matchingVideoModelIndex = allVideoModels.firstIndex(where: { $0.generationId == generationId }) {
                            let matchingVideoModel = allVideoModels[matchingVideoModelIndex]

                            if matchingVideoModel.isFinished == false {
                                self.pollGenerationStatus(
                                    generationId: matchingVideoModel.generationId,
                                    selectedTemplateEffect: matchingVideoModel.name,
                                    imagePath: matchingVideoModel.imagePath ?? ""
                                )
                            }
                        }
                    } else {
                        let allVideoModels = CacheManager.shared.loadAllVideoModels()

                        if let matchingVideoModel = allVideoModels.first(where: { $0.generationId == generationId }) {
                            self.pollGenerationStatus(
                                generationId: matchingVideoModel.generationId,
                                selectedTemplateEffect: matchingVideoModel.name,
                                imagePath: matchingVideoModel.imagePath ?? ""
                            )
                        }
                    }
                case let .failure(error):
                    print("Failed to fetch status: \(error.localizedDescription)")
                }
            }
        }
    }

    func pollGenerationStatus(generationId: String, selectedTemplateEffect: String, imagePath: String) {
        var permanentImagePath: String?

        if let image = UIImage(named: imagePath) {
            if let savedImageURL = saveImageToPermanentDirectory(image) {
                permanentImagePath = savedImageURL.path
            }
        }

        var timer: Timer?
        let videoId = UUID()
        let creationDate = Date()

        var finalImagePath = permanentImagePath ?? imagePath
        var existingModel: GeneratedVideoModel?

        let allVideoModels = CacheManager.shared.loadAllVideoModels()
        if let model = allVideoModels.first(where: { $0.generationId == generationId }) {
            existingModel = model
            finalImagePath = model.imagePath ?? finalImagePath
        }

        let initialVideo = existingModel ?? GeneratedVideoModel(
            id: videoId,
            name: selectedTemplateEffect,
            video: nil,
            imagePath: finalImagePath,
            isFinished: false,
            createdAt: creationDate,
            generationId: generationId
        )

        CacheManager.shared.saveOrUpdateVideoModel(initialVideo) { success in
            if success {
                print("Initial MyVideoModel cached successfully.")
            } else {
                print("Failed to cache initial MyVideoModel.")
            }
        }

        func fetchStatus() {
            NetworkService.shared.fetchEffectGenerationStatus(generationId: generationId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case let .success(data):

                        if data.status == "finished", let resultUrl = data.resultUrl {
                            if let existingModel = CacheManager.shared.loadAllVideoModels().first(where: { $0.generationId == generationId }) {
                                var updatedVideo = existingModel
                                updatedVideo.video = resultUrl
                                updatedVideo.isFinished = true
                                updatedVideo.imagePath = nil
                                CacheManager.shared.saveOrUpdateVideoModel(updatedVideo) { success in
                                    if success {
                                        print("Updated MyVideoModel cached successfully.")
                                    } else {
                                        print("Failed to cache updated MyVideoModel.")
                                    }
                                }
                            }

                            let updatedVideo = GeneratedVideoModel(
                                id: videoId,
                                name: selectedTemplateEffect,
                                video: resultUrl,
                                imagePath: nil,
                                isFinished: true,
                                createdAt: creationDate,
                                generationId: generationId
                            )

                            let generationCountToPass = self.generationCount
                            let resultVC = AiEffectsResultViewController(model: updatedVideo, generationCount: generationCountToPass, fromGeneration: true)
                            resultVC.delegate = self
                            let navigationController = UINavigationController(rootViewController: resultVC)
                            navigationController.modalPresentationStyle = .fullScreen
                            self.present(navigationController, animated: true, completion: nil)

                            self.activeGenerationCount -= 1
                            timer?.invalidate()
                        } else if data.status == "error" {
                            if self.isFirstGeneration {
                                self.generationCount -= 1
                            }
                            self.generationIdError()
                            timer?.invalidate()
                        } else {
                            print("Status: \(data.status), Progress: \(data.progress ?? 0)%")
                        }
                    case let .failure(error):
                        if let networkError = error as? NetworkError {
                            switch networkError {
                            case let .serverError(statusCode) where statusCode == 500:
                                print("Server error: 500. Retrying...")
                            default:
                                print("Error while polling: \(networkError)")
                                self.generationErrorAlert(generationId: generationId,
                                                          selectedTemplateEffect: selectedTemplateEffect,
                                                          imagePath: imagePath)
                                timer?.invalidate()
                            }
                        } else {
                            print("Unknown error: \(error)")
                            self.generationErrorAlert(
                                generationId: generationId,
                                selectedTemplateEffect: selectedTemplateEffect,
                                imagePath: imagePath
                            )
                            timer?.invalidate()
                        }

                        self.activeGenerationCount -= 1

                        if self.isFirstGeneration {
                            self.generationCount -= 1
                        }
                    }
                }
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            fetchStatus()
        }
    }

    private func generationErrorAlert(generationId: String, selectedTemplateEffect: String, imagePath: String) {
        let alert = UIAlertController(title: L.videoGenerationError,
                                      message: L.errorVideoGalleryMessage,
                                      preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: L.cancel, style: .cancel)
        let tryAgainAction = UIAlertAction(title: L.tryAgain, style: .default) { _ in
            self.pollGenerationStatus(
                generationId: generationId,
                selectedTemplateEffect: selectedTemplateEffect,
                imagePath: imagePath
            )
        }

        alert.addAction(cancelAction)
        alert.addAction(tryAgainAction)
        alert.overrideUserInterfaceStyle = .dark
        present(alert, animated: true)
    }

    private func checkGenerationStatus() {
        let alert = UIAlertController(
            title: L.previousGeneration,
            message: L.previousGenerationMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.overrideUserInterfaceStyle = .dark
        present(alert, animated: true)
    }

    private func generationIdError() {
        activeGenerationCount -= 1
        let alert = UIAlertController(
            title: L.videoGenerationError,
            message: L.tryDifferentPhoto,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.overrideUserInterfaceStyle = .dark
        present(alert, animated: true, completion: nil)
    }

    private func cleanUnfinishedVideos() {
        let allModels = CacheManager.shared.loadAllVideoModels()
        let unfinishedModels = allModels.filter { $0.isFinished == false }

        for model in unfinishedModels {
            CacheManager.shared.deleteVideoModel(withId: model.id)
        }
    }

    private func saveImageToTemporaryDirectory(_ image: UIImage) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            if let jpegData = image.jpegData(compressionQuality: 0.8) {
                try jpegData.write(to: fileURL)
                return fileURL
            } else {
                print("Failed to convert image to JPEG")
            }
        } catch {
            print("Failed to save image to temporary directory: \(error)")
        }

        return nil
    }

    private func saveImageToPermanentDirectory(_ image: UIImage) -> URL? {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let fileName = UUID().uuidString + ".jpg"

        let fileURL = cachesDirectory.appendingPathComponent(fileName)

        do {
            if let jpegData = image.jpegData(compressionQuality: 0.8) {
                try jpegData.write(to: fileURL)
                return fileURL
            } else {
                print("Failed to convert image to JPEG")
            }
        } catch {
            print("Failed to save image to caches directory: \(error)")
        }

        return nil
    }
}

//MARK: - SelectImageViewDelegate
extension OpenEffectsViewController: SelectImageViewDelegate {
    func didTapAddPhoto(sender: SelectImageView) {
        if !purchaseManager.hasUnlockedPro {
            openSubVC()
        } else {
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
                self.selectButtonTapped(sender: sender)
            }

            let takePhotoAction = UIAlertAction(
                title: L.takePphoto,
                style: .default
            ) { _ in
                self.photoButtonTapped(sender: sender)
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
}

// MARK: - UIImagePickerControllerDelegate
extension OpenEffectsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            let resizedImage = resizeImageIfNeeded(image: selectedImage, maxWidth: 1260, maxHeight: 760)

            if let activeTag = activeImageViewTag {
                switch activeTag {
                case 1:
                    self.selectedImage = resizedImage
                    self.selectImageView.addImage(image: selectedImage)
                case 2:
                    self.selectedFirstDoubleImage = resizedImage
                    self.selectFirstDoubleImageView.addImage(image: selectedImage)
                case 3:
                    self.selectedSecondDoubleImage = resizedImage
                    self.selectSecondDoubleImageView.addImage(image: selectedImage)
                default:
                    break
                }
            }

            var imagePath: String?

            if let imageURL = info[.imageURL] as? URL {
                imagePath = imageURL.path
            } else {
                let tempDirectory = FileManager.default.temporaryDirectory
                let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")

                if let imageData = resizedImage.jpegData(compressionQuality: 1.0) {
                    do {
                        try imageData.write(to: tempFileURL)
                        imagePath = tempFileURL.path
                    } catch {
                        print("Failed to save camera photo to temporary directory: \(error)")
                        imagePath = nil
                    }
                }
            }

            if let activeTag = activeImageViewTag {
                switch activeTag {
                case 1:
                    self.selectedImagePath = imagePath
                case 2:
                    self.selectedFirstDoubleImagePath = imagePath
                case 3:
                    self.selectedSecondDoubleImagePath = imagePath
                default:
                    break
                }
            }
        }
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

// MARK: - AiEffectsResultViewControllerDelegate
extension OpenEffectsViewController: AiEffectsResultViewControllerDelegate {
    func didTapCloseButton() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
