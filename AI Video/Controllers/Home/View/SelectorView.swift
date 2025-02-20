import SnapKit
import UIKit

protocol SelectorDelegate: AnyObject {
    func didSelect(at index: Int)
}

final class SelectorView: UIControl {
    private let mainContainerView = UIView()

    private let textView = UIImageView()
    private let photoView = UIImageView()

    private let textLabel = UILabel()
    private let photoLabel = UILabel()

    private let containerStackView = UIStackView()

    private var selectedIndex: Int = 0 {
        didSet {
            updateViewsAppearance()
        }
    }

    private var views: [UIView] = []
    weak var delegate: SelectorDelegate?

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
        mainContainerView.do { make in
            make.backgroundColor = UIColor.bgTertiary
            make.layer.cornerRadius = 12
        }

        textView.do { make in
            make.backgroundColor = UIColor.accentPrimary
            make.isUserInteractionEnabled = true
            make.layer.cornerRadius = 12
        }

        photoView.do { make in
            make.backgroundColor = .clear
            make.isUserInteractionEnabled = true
            make.layer.cornerRadius = 12
        }

        containerStackView.do { make in
            make.axis = .horizontal
            make.spacing = 0
            make.distribution = .fillEqually
        }

        [textLabel, photoLabel].forEach { label in
            label.do { make in
                make.textColor = UIColor.labelsPrimary
            }
        }

        textLabel.text = L.usingText
        photoLabel.text = L.usingPhoto

        textLabel.textAlignment = .center
        photoLabel.textAlignment = .center

        textView.addSubview(textLabel)
        photoView.addSubview(photoLabel)

        containerStackView.addArrangedSubviews(
            [textView, photoView]
        )
        mainContainerView.addSubviews(containerStackView)
        addSubview(mainContainerView)

        let tapGestureRecognizers = [
            UITapGestureRecognizer(target: self, action: #selector(allTapped)),
            UITapGestureRecognizer(target: self, action: #selector(fastestTapped))
        ]

        textView.addGestureRecognizer(tapGestureRecognizers[0])
        photoView.addGestureRecognizer(tapGestureRecognizers[1])

        views = [textView, photoView]
        updateViewsAppearance()
    }

    private func setupConstraints() {
        mainContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        [textLabel, photoLabel].forEach { label in
            label.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }

        containerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(48)
        }

        textView.snp.makeConstraints { make in
            make.top.equalTo(containerStackView.snp.top).offset(2)
            make.bottom.equalTo(containerStackView.snp.bottom).offset(-2)
            make.leading.equalTo(containerStackView.snp.leading).offset(2)
            make.height.equalTo(45)
        }

        photoView.snp.makeConstraints { make in
            make.top.equalTo(containerStackView.snp.top).offset(2)
            make.bottom.equalTo(containerStackView.snp.bottom).offset(-2)
            make.trailing.equalTo(containerStackView.snp.trailing).offset(-2)
            make.height.equalTo(45)
        }
    }

    @objc private func allTapped() {
        selectedIndex = 0
    }

    @objc private func fastestTapped() {
        selectedIndex = 1
    }

    @objc private func favouritesTapped() {
        selectedIndex = 2
    }

    private func updateViewsAppearance() {
        for (index, view) in views.enumerated() {
            let isSelected = index == selectedIndex
            let imageView = view as? UIImageView
            let label = view.subviews.first as? UILabel

            imageView?.backgroundColor = isSelected ? UIColor.accentPrimary : .clear
            label?.font = isSelected ? UIFont.CustomFont.footnoteEmphasized : UIFont.CustomFont.footnoteRegular
        }

        delegate?.didSelect(at: selectedIndex)
    }

    func configure(selectedIndex: Int) {
        guard selectedIndex >= 0 && selectedIndex < views.count else {
            fatalError("Invalid index provided for PersonnelSelectionView configuration")
        }
        self.selectedIndex = selectedIndex
    }

    func updateFirstLabel(_ text: String) {
        textLabel.text = text
    }

    func updateSecondLabel(_ text: String) {
        photoLabel.text = text
    }
}
