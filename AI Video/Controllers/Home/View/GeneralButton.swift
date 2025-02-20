import UIKit

final class GeneralButton: UIControl {
    // MARK: - Properties

    override var isHighlighted: Bool {
        didSet {
            configureAppearance()
        }
    }

    private let titleLabel = UILabel()
    let buttonContainer = UIView()

    private let stackView = UIStackView()
    private let plusImageView = UIImageView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        drawSelf()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private methods

    private func drawSelf() {
        plusImageView.image = UIImage(named: "plus_icon")

        buttonContainer.do { make in
            make.backgroundColor = UIColor.accentPrimary
            make.layer.cornerRadius = 12
            make.isUserInteractionEnabled = false
        }

        titleLabel.do { make in
            make.text = L.next
            make.textColor = UIColor.text
            make.font = UIFont.CustomFont.bodyEmphasized
            make.isUserInteractionEnabled = false
        }

        stackView.do { make in
            make.axis = .horizontal
            make.alignment = .center
            make.spacing = 2
            make.distribution = .fillProportionally
            make.isUserInteractionEnabled = false
        }

        buttonContainer.addSubview(titleLabel)
        addSubviews(buttonContainer)

        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        buttonContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func configureAppearance() {
        alpha = isHighlighted ? 0.7 : 1
    }

    func setTitle(to title: String) {
        titleLabel.text = title
    }

    func setTextColor(_ color: UIColor) {
        titleLabel.textColor = color
    }

    func setBackgroundColor(_ color: UIColor) {
        buttonContainer.backgroundColor = color
    }

    func addPhoto() {
        titleLabel.removeFromSuperview()
        titleLabel.text = L.addPhoto
        stackView.addArrangedSubviews([plusImageView, titleLabel])
        addSubviews(stackView)

        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    func addFirstImage() {
        titleLabel.removeFromSuperview()
        titleLabel.text = L.image1
        stackView.addArrangedSubviews([plusImageView, titleLabel])
        addSubviews(stackView)

        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    func addSecondImage() {
        titleLabel.removeFromSuperview()
        titleLabel.text = L.image2
        stackView.addArrangedSubviews([plusImageView, titleLabel])
        addSubviews(stackView)

        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
