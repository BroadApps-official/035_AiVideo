import AVFoundation
import AVKit
import SnapKit
import UIKit

protocol AiEffectsResultViewControllerDelegate: AnyObject {
    func didTapCloseButton()
}

final class AiEffectsResultViewController: UIViewController {
    // MARK: - Properties

    private let backButton = UIButton(type: .system)
    private let menuButton = UIButton(type: .system)

    private let playButton = UIButton()
    let blurEffect = UIBlurEffect(style: .light)
    private let blurEffectView: UIVisualEffectView

    private var playerViewController: AVPlayerViewController?
    private var player: AVPlayer?
    private var generatedURL: String?
    private var model: GeneratedVideoModel
    private let generationCount: Int
    private var fromGeneration: Bool
    private var aspectRatio: CGFloat = 15 / 9
    private var isPlaying = false

    private let saveButton = GeneralButton()
    weak var delegate: AiEffectsResultViewControllerDelegate?

    // MARK: - Init
    init(model: GeneratedVideoModel, generationCount: Int, fromGeneration: Bool) {
        self.model = model
        self.generationCount = generationCount
        self.fromGeneration = fromGeneration
        generatedURL = model.video
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

        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFont.CustomFont.bodyEmphasized,
            .foregroundColor: UIColor.labelsPrimary
        ]

        setupBackButton()
        setupMenuButton()
        view.backgroundColor = UIColor.bgPrimary

        drawSelf()
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(saveButtonTapped))
        saveButton.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(saveButton)
        navigationItem.title = model.name
    }

    private func drawSelf() {
        saveButton.setTitle(to: L.save)
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
        
        guard let videoURL = CacheManager.shared.loadVideo(in: model) else {
            print("Video is not in cache")
            return
        }

        let asset = AVAsset(url: videoURL)
        let track = asset.tracks(withMediaType: .video).first

        if let naturalSize = track?.naturalSize {
            let width = naturalSize.width
            let height = naturalSize.height
            aspectRatio = width / height
        }

        player = AVPlayer(url: videoURL)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player

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
                make.height.equalTo(view.snp.width).multipliedBy(1 / aspectRatio).offset(-66)
            }
            
            view.addSubview(blurEffectView)
            view.addSubview(playButton)

            playButton.snp.makeConstraints { make in
                make.center.equalTo(playerVC.view.snp.center)
                make.size.equalTo(64)
            }
            
            blurEffectView.snp.makeConstraints { make in
                make.edges.equalTo(playButton.snp.edges)
            }
        }
        
        view.addSubview(saveButton)

        saveButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
            make.height.equalTo(48)
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

    @objc private func didTapPlayButton() {
        if isPlaying {
            player?.pause()
            playButton.setImage(UIImage(named: "main_play_icon"), for: .normal)
        } else {
            player?.play()
            playButton.setImage(UIImage(named: "main_pause_icon"), for: .normal)
        }
        isPlaying.toggle()
    }

    @objc private func didFinishPlaying() {
        player?.seek(to: .zero)

        playButton.setImage(UIImage(named: "main_play_icon"), for: .normal)
        isPlaying = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func saveButtonTapped() {
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
    
    private func shareVideo() {
        guard let videoURL = CacheManager.shared.loadVideo(in: model) else {
            print("Video doesn't exist.")
            return
        }
        
        if FileManager.default.fileExists(atPath: videoURL.path) {
            let activityViewController = UIActivityViewController(activityItems: [videoURL], applicationActivities: nil)
            present(activityViewController, animated: true)
        } else {
            print("Video doesn't exist.")
        }
    }

    private func saveToFiles() {
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

    @objc private func deleteVideo() {
        let alert = UIAlertController(title: L.deleteVideo,
                                      message: L.deleteVideoMessage,
                                      preferredStyle: .actionSheet)

        let deleteAction = UIAlertAction(title: L.delete, style: .destructive) { _ in
            CacheManager.shared.deleteVideoModel(withId: self.model.id)
            self.dismiss(animated: true, completion: nil)
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

// MARK: - UIDocumentPickerDelegate
extension AiEffectsResultViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        videoFilesSuccessAlert()
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        videoFilesErrorAlert()
    }
}

// MARK: - Alerts
extension AiEffectsResultViewController {
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
