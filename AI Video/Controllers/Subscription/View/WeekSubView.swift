import UIKit

protocol WeekSubViewDelegate: AnyObject {
    func didTapWeekSubView(isOn: Bool)
}

final class WeekSubView: UIControl {
    override var isSelected: Bool {
        didSet {
            configureAppearance()
        }
    }

    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let underPriceLabel = UILabel()
    private let priceStackView = UIStackView()
    private let containerView = UIView()
    private let lineView = UIView()

    weak var delegate: WeekSubViewDelegate?

    var dynamicTitle: String?
    var dynamicPrice: String?

    init() {
        super.init(frame: .zero)
        setupView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .clear
        containerView.isUserInteractionEnabled = false
        
        lineView.do { make in
            make.backgroundColor = UIColor.separatorPrimary
        }

        containerView.do { make in
            make.backgroundColor = UIColor.bgTertiary
            make.layer.cornerRadius = 10
        }

        titleLabel.do { make in
            make.text = L.weekly
            make.textAlignment = .center
            make.font = UIFont.CustomFont.bodyRegular
            make.textColor = UIColor.labelsPrimary
        }

        priceLabel.do { make in
            make.font = UIFont.CustomFont.bodyEmphasized
            make.text = "$4.99"
            make.textAlignment = .center
            make.textColor = UIColor.labelsPrimary
        }

        underPriceLabel.do { make in
            make.text = "per week"
            make.textColor = UIColor.labelsTertiary
            make.font = UIFont.CustomFont.caption1Regular
            make.textAlignment = .center
        }

        priceStackView.do { make in
            make.axis = .vertical
            make.spacing = 2
            make.alignment = .trailing
            make.distribution = .fill
        }

        priceStackView.addArrangedSubviews([priceLabel, underPriceLabel])
        addSubviews(containerView, titleLabel, priceStackView, lineView)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(28)
        }

        priceStackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(28)
            make.centerY.equalToSuperview()
        }
        
        lineView.snp.makeConstraints { make in
            make.top.equalTo(priceStackView.snp.top)
            make.bottom.equalTo(priceStackView.snp.bottom)
            make.width.equalTo(1)
            make.trailing.equalTo(priceStackView.snp.leading).offset(-16)
        }
    }

    private func configureAppearance() {
        if isSelected {
            containerView.layer.borderColor = UIColor.accentPrimary.cgColor
            containerView.layer.borderWidth = 2
            containerView.backgroundColor = UIColor.bgPrimary
            priceLabel.textColor = UIColor.accentPrimary
        } else {
            containerView.layer.borderColor = UIColor.clear.cgColor
            containerView.layer.borderWidth = 0
            containerView.backgroundColor = UIColor.bgTertiary
            priceLabel.textColor = UIColor.labelsPrimary
        }
    }

    func updateDetails(title: String, price: String) {
        dynamicTitle = title
        dynamicPrice = price

        titleLabel.text = dynamicTitle ?? L.weekly
        priceLabel.text = dynamicPrice ?? "$4.99"
        underPriceLabel.text = "per week"
    }

    // MARK: - Actions

    @objc private func didTapView() {
        guard !isSelected else { return }
        isSelected.toggle()
        delegate?.didTapWeekSubView(isOn: isSelected)
    }
}
