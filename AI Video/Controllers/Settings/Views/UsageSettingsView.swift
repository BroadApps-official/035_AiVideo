import SnapKit
import UIKit

protocol UsageSettingsViewDelegate: AnyObject {
    func didTapUsageView()
}

final class UsageSettingsView: UIControl {
    weak var delegate: UsageSettingsViewDelegate?

    private let buttonBackgroundView = UIButton(type: .system)
    private let typeImageView = UIImageView()
    private let titleLabel = UILabel()
    private let arrowImageView = UIImageView()

    private var observation: NSKeyValueObservation?

    // MARK: - Init

    init(delegate: UsageSettingsViewDelegate) {
        self.delegate = delegate

        super.init(frame: .zero)
        drawSelf()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Draw

    private func drawSelf() {
        buttonBackgroundView.addTarget(self, action: #selector(didTapView), for: .touchUpInside)
        buttonBackgroundView.backgroundColor = UIColor.bgPrimaryAlpha
        buttonBackgroundView.layer.cornerRadius = 10

        observation = buttonBackgroundView.observe(\.isHighlighted, options: [.old, .new], changeHandler: { [weak self] _, change in
            guard let self, let oldValue = change.oldValue, let newValue = change.newValue else {
                return
            }
            guard oldValue != newValue else { return }

            titleLabel.textColor = newValue ? .white.withAlphaComponent(0.7) : .white
        })

        arrowImageView.image = UIImage(named: "set_arrow_icon")
        typeImageView.image = UIImage(named: "set_usage_icon")
        typeImageView.contentMode = .scaleAspectFit
        buttonBackgroundView.isUserInteractionEnabled = true

        titleLabel.do { make in
            make.textColor = UIColor.labelsPrimary
            make.font = UIFont.CustomFont.bodyRegular
            make.text = L.usage
        }

        addSubviews(buttonBackgroundView)
        buttonBackgroundView.addSubview(titleLabel)
        buttonBackgroundView.addSubview(typeImageView)
        buttonBackgroundView.addSubview(arrowImageView)

        buttonBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        typeImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(typeImageView.snp.trailing).offset(12)
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }
    }

    // MARK: - Actions

    @objc private func didTapView() {
        delegate?.didTapUsageView()
    }
}
