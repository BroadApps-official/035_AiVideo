import SnapKit
import UIKit

protocol StyleSelectionDelegate: AnyObject {
    func didSelectStyle(selectedIndex: Int)
}

final class StyleSelectionView: UIControl {
    private let mainContainerView = UIView()

    private let noStyleView = UIImageView()
    private let realisticView = UIImageView()
    private let pixarView = UIImageView()
    private let cyberpunkView = UIImageView()

    private let noStyleLabel = UILabel()
    private let realisticLabel = UILabel()
    private let pixarLabel = UILabel()
    private let cyberpunkLabel = UILabel()

    private let styleStackView = UIStackView()

    private var selectedIndex: Int? {
        didSet {
            updateViewsAppearance()
        }
    }

    private var views: [UIImageView] = []
    weak var delegate: StyleSelectionDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        noStyleView.image = UIImage(named: "style_no")
        realisticView.image = UIImage(named: "style_realistic")
        pixarView.image = UIImage(named: "style_pixar")
        cyberpunkView.image = UIImage(named: "style_cyberpunk")

        noStyleView.isUserInteractionEnabled = true
        realisticView.isUserInteractionEnabled = true
        pixarView.isUserInteractionEnabled = true
        cyberpunkView.isUserInteractionEnabled = true

        [noStyleLabel, realisticLabel, pixarLabel, cyberpunkLabel].forEach { label in
            label.do { make in
                make.font = UIFont.CustomFont.footnoteEmphasized
                make.textColor = UIColor.labelsQuintuple
                make.textAlignment = .center
            }
        }

        noStyleLabel.text = L.noStyle
        realisticLabel.text = L.realistic
        pixarLabel.text = L.pixar
        cyberpunkLabel.text = L.cyberpunk

        styleStackView.do { make in
            make.axis = .horizontal
            make.spacing = 16
            make.distribution = .fillEqually
            make.alignment = .leading
        }

        noStyleView.addSubviews(noStyleLabel)
        realisticView.addSubviews(realisticLabel)
        pixarView.addSubviews(pixarLabel)
        cyberpunkView.addSubviews(cyberpunkLabel)

        styleStackView.addArrangedSubview(noStyleView)
        styleStackView.addArrangedSubview(realisticView)
        styleStackView.addArrangedSubview(pixarView)
        styleStackView.addArrangedSubview(cyberpunkView)

        addSubviews(styleStackView)

        let tapGestureRecognizers = [
            UITapGestureRecognizer(target: self, action: #selector(genreTapped(_:))),
            UITapGestureRecognizer(target: self, action: #selector(genreTapped(_:))),
            UITapGestureRecognizer(target: self, action: #selector(genreTapped(_:))),
            UITapGestureRecognizer(target: self, action: #selector(genreTapped(_:)))
        ]

        noStyleView.addGestureRecognizer(tapGestureRecognizers[0])
        realisticView.addGestureRecognizer(tapGestureRecognizers[1])
        pixarView.addGestureRecognizer(tapGestureRecognizers[2])
        cyberpunkView.addGestureRecognizer(tapGestureRecognizers[3])

        views = [
            noStyleView, realisticView, pixarView, cyberpunkView
        ]
        updateViewsAppearance()
    }

    private func setupConstraints() {
        styleStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.bottom.equalToSuperview()
        }

        [noStyleView, realisticView, pixarView, cyberpunkView].forEach { view in
            view.snp.makeConstraints { make in
                make.size.equalTo(80)
            }
        }

        [noStyleLabel, realisticLabel, pixarLabel, cyberpunkLabel].forEach { label in
            label.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().offset(16)
            }
        }
    }

    @objc private func genreTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedView = sender.view as? UIImageView else { return }
        guard let index = views.firstIndex(of: tappedView) else { return }

        if selectedIndex == index {
            selectedIndex = nil
        } else {
            selectedIndex = index
        }

        delegate?.didSelectStyle(selectedIndex: selectedIndex ?? -1)
    }

    private func updateViewsAppearance() {
        for (index, view) in views.enumerated() {
            if selectedIndex == index {
                view.layer.borderWidth = 2
                view.layer.cornerRadius = 8
                view.layer.borderColor = UIColor.separatorPrimary.cgColor
                view.alpha = 1
            } else {
                view.layer.borderWidth = 0
                view.alpha = 0.6
            }
        }
    }

    func configure(selectedIndex: Int?) {
        self.selectedIndex = selectedIndex
    }

    func configureForCell(selectedIndex: Int?) {
        self.selectedIndex = selectedIndex

        styleStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        for (index, view) in views.enumerated() {
            if selectedIndex == index {
                view.layer.borderWidth = 2
                view.layer.cornerRadius = 8
                view.layer.borderColor = UIColor.separatorPrimary.cgColor
                view.alpha = 1
            } else {
                view.layer.borderWidth = 0
                view.alpha = 0.6
            }
        }
    }
}
