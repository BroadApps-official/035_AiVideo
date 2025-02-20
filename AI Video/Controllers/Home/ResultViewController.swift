import AVFoundation
import AVKit
import SnapKit
import UIKit

protocol ResultViewControllerDelegate: AnyObject {
    func didTapCloseButton()
}

final class ResultViewController: UIViewController {
    // MARK: - Properties

    private let backButton = UIButton(type: .system)
    private let menuButton = UIButton(type: .system)

    private var generatedURL: URL?
    private var model: GeneratedVideo
    
    private let promptView = TextView(type: .description)
    private let saveButton = GeneralButton()
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private var fromGeneration: Bool
    private let generationCount: Int
    weak var delegate: ResultViewControllerDelegate?
    
    private let playButton = UIButton()
    let blurEffect = UIBlurEffect(style: .light)
    private let blurEffectView: UIVisualEffectView
    
    private var playerViewController: AVPlayerViewController?
    private var player: AVPlayer?
    private var isPlaying = false
    private var aspectRatio: CGFloat = 16 / 9
    
    private let promptLabel = UILabel()
    private let copyButton = UIButton()

    // MARK: - Init
    init(model: GeneratedVideo, generationCount: Int, fromGeneration: Bool) {
        self.model = model
        self.generationCount = generationCount
        self.fromGeneration = fromGeneration
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = false

        navigationItem.title = L.aiVideo

        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFont.CustomFont.headlineRegular,
            .foregroundColor: UIColor.labelsPrimary
        ]
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.bgPrimary
        appearance.titleTextAttributes = [
            .font: UIFont.CustomFont.headlineRegular,
            .foregroundColor: UIColor.labelsPrimary
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        setupBackButton()
        setupMenuButton()
        view.backgroundColor = UIColor.bgPrimary

        drawSelf()

        NotificationCenter.default.addObserver(self, selector: #selector(didFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)

        let tapPlayGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPlayButton))
        playerViewController?.view.addGestureRecognizer(tapPlayGesture)

        let saveTapGesture = UITapGestureRecognizer(target: self, action: #selector(saveButtonTapped))
        saveButton.addGestureRecognizer(saveTapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        promptView.textView.text = model.prompt
        view.bringSubviewToFront(saveButton)
    }

    private func drawSelf() {
        saveButton.setTitle(to: L.save)
        promptView.textView.isScrollEnabled = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isScrollEnabled = true
        
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
        
        promptLabel.do { make in
            make.text = L.prompt
            make.font = UIFont.CustomFont.title2Emphasized
            make.textColor = UIColor.labelsSecondary
            make.textAlignment = .left
        }
        
        copyButton.do { make in
            make.backgroundColor = UIColor.accentPrimaryAlpha
            make.setImage(UIImage(named: "copy_icon"), for: .normal)
            make.setTitle(L.copy, for: .normal)
            make.setTitleColor(UIColor.labelsPrimary, for: .normal)
            make.titleLabel?.font = UIFont.CustomFont.footnoteEmphasized
            make.titleLabel?.isUserInteractionEnabled = false
            make.layer.cornerRadius = 12
            make.isHidden = false
            make.addTarget(self, action: #selector(copyButtonTapped), for: .touchUpInside)
        }
        
        let video = self.model

        CacheManager.shared.loadVideoByModel(video) { [weak self] result in
            switch result {
            case let .success(videoURL):
                self?.loadAndPlayVideo(from: videoURL)
            case let .failure(error):
                print("Error loading video for template \(String(describing: video.id)): \(error.localizedDescription)")
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
            contentView.addSubview(playerVC.view)
            playerVC.videoGravity = .resizeAspectFill
            playerVC.view.layer.cornerRadius = 20
            playerVC.view.layer.masksToBounds = true
            playerVC.didMove(toParent: self)
            
            contentView.addSubview(blurEffectView)
            contentView.addSubview(playButton)
            
            view.addSubview(scrollView)
            scrollView.addSubview(contentView)
            contentView.addSubviews(promptLabel, copyButton, promptView)
            view.addSubviews(saveButton)
            
            view.bringSubviewToFront(saveButton)
            
            playerVC.view.snp.makeConstraints { make in
                make.top.equalTo(contentView.snp.top)
                make.leading.trailing.equalToSuperview().inset(16)
                make.height.equalTo(view.snp.width)
            }
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(saveButton.snp.top).offset(-8)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
            make.bottom.equalTo(promptView.snp.bottom).offset(16)
        }
        
        promptLabel.snp.makeConstraints { make in
            make.top.equalTo(playerViewController?.view.snp.bottom ?? view.snp.bottom).offset(23)
            make.leading.equalToSuperview().offset(16)
        }
        
        copyButton.snp.makeConstraints { make in
            make.centerY.equalTo(promptLabel.snp.centerY)
            make.trailing.equalToSuperview().inset(16)
            make.width.equalTo(81)
        }

        promptView.snp.makeConstraints { make in
            make.top.equalTo(promptLabel.snp.bottom).offset(19)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        saveButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
            make.height.equalTo(48)
        }
        
        playButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(playerViewController?.view.snp.centerY ?? view.snp.centerY)
            make.size.equalTo(64)
        }

        blurEffectView.snp.makeConstraints { make in
            make.edges.equalTo(playButton.snp.edges)
        }
    }

    private func setupBackButton() {
        backButton.do { make in
            make.setTitleColor(UIColor.accentPrimary, for: .normal)
            make.setImage(UIImage(systemName: "chevron.left"), for: .normal)
            make.tintColor = UIColor.accentPrimary
            make.semanticContentAttribute = .forceLeftToRight

            make.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        }

        let backBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = backBarButtonItem
    }
    
    private func setupMenuButton() {
        menuButton.do { make in
            make.setImage(UIImage(named: "result_menu_button")?.withRenderingMode(.alwaysOriginal), for: .normal)
            make.addTarget(self, action: #selector(didTapMenuButton), for: .touchUpInside)
        }

        let shareAction = UIAction(title: L.share, image: UIImage(systemName: "square.and.arrow.up")) { _ in
            self.shareVideo()
        }

        let saveToFileAction = UIAction(title: L.saveFiles, image: UIImage(systemName: "folder.badge.plus")) { _ in
            self.saveToFiles()
        }

        let deleteAction = UIAction(title: L.delete, image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            self.deleteVideo()
        }

        let menu = UIMenu(title: "", children: [shareAction, saveToFileAction, deleteAction])
        menuButton.menu = menu
        menuButton.showsMenuAsPrimaryAction = true

        let menuBarButtonItem = UIBarButtonItem(customView: menuButton)
        navigationItem.rightBarButtonItem = menuBarButtonItem
    }
    
    @objc private func didTapMenuButton() {
        DispatchQueue.main.async {
            self.menuButton.overrideUserInterfaceStyle = .dark
        }
    }
    
    @objc private func copyButtonTapped() {
        let prompt = model.prompt
        UIPasteboard.general.string = prompt
        
        let alert = UIAlertController(title: "Copied", message: "Text copied to clipboard.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.overrideUserInterfaceStyle = .dark
        present(alert, animated: true)
    }
    
    @objc private func didTapCloseButton() {
        if fromGeneration {
            if shouldOpenForGenerationCount(generationCount) {
                dismiss(animated: true) {
                    self.delegate?.didTapCloseButton()
                }
            } else {
                dismiss(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }

    private func shouldOpenForGenerationCount(_ count: Int) -> Bool {
        return count == 1 || count == 3 || count == 5 || count % 10 == 0
    }

    @objc private func saveButtonTapped() {
        let videoId = model.id
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
    
    private func shareVideo() {
        let videoURL = model.cacheURL
        if FileManager.default.fileExists(atPath: videoURL.path) {
            let activityViewController = UIActivityViewController(activityItems: [videoURL], applicationActivities: nil)
            present(activityViewController, animated: true)
        } else {
            print("Video doesn't exist.")
        }
    }

    private func saveToFiles() {
        let videoID = model.id
        let videoURL = model.cacheURL
        
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

    @objc private func deleteVideo() {
        let alert = UIAlertController(title: L.deleteVideo,
                                      message: L.deleteVideoMessage,
                                      preferredStyle: .alert)

        let deleteAction = UIAlertAction(title: L.delete, style: .destructive) { _ in
            let videoId = self.model.id
            CacheManager.shared.deleteGeneratedVideoModel(withId: videoId)
            self.dismiss(animated: true, completion: nil)
        }

        let cancelAction = UIAlertAction(title: L.cancel, style: .cancel) { _ in
            print("Photo deletion was cancelled.")
        }

        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        alert.overrideUserInterfaceStyle = .dark
        present(alert, animated: true)
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

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UIDocumentPickerDelegate
extension ResultViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        videoFilesSuccessAlert()
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        videoFilesErrorAlert()
    }
}

// MARK: - Alerts
extension ResultViewController {
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
            self.saveButtonTapped()
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
            self.saveToFiles()
        }

        alert.addAction(cancelAction)
        alert.addAction(tryAgainAction)
        alert.overrideUserInterfaceStyle = .dark
        present(alert, animated: true)
    }
}
