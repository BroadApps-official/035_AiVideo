import SnapKit
import UIKit

final class SubscribeView: UIControl {
    private let unrealLabel = UILabel()

    private let firstLabel = UILabel()
    private let secondLabel = UILabel()
    private let thirdLabel = UILabel()

    private let firstImageView = UIImageView()
    private let secondImageView = UIImageView()
    private let thirdImageView = UIImageView()

    private let firstStackView = UIStackView()
    private let secondStackView = UIStackView()
    private let thirdStackView = UIStackView()
    private let mainStackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        drawSelf()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func drawSelf() {
        backgroundColor = .clear
        [firstImageView, secondImageView, thirdImageView].forEach { imageView in
            imageView.do { make in
                make.image = UIImage(named: "sub_check_icon")
            }
        }

        unrealLabel.do { make in
            make.text = L.unrealLabel
            make.font = UIFont.CustomFont.title1Emphasized
            make.textColor = UIColor.labelsPrimary
            make.textAlignment = .center
        }

        [firstLabel, secondLabel, thirdLabel].forEach { label in
            label.do { make in
                make.font = UIFont.CustomFont.subheadlineEmphasized
                make.textColor = UIColor.labelsSecondary
                make.textAlignment = .center
            }
        }
        
        firstLabel.text = L.subFirstLabel
        secondLabel.text = L.subSecondLabel
        thirdLabel.text = L.subThirdLabel

        [firstStackView, secondStackView, thirdStackView].forEach { stackView in
            stackView.do { make in
                make.axis = .horizontal
                make.spacing = 4
                make.distribution = .fill
            }
        }

        mainStackView.do { make in
            make.axis = .vertical
            make.spacing = 16
            make.distribution = .fill
            make.alignment = .leading
        }

        firstStackView.addArrangedSubviews([firstImageView, firstLabel])
        secondStackView.addArrangedSubviews([secondImageView, secondLabel])
        thirdStackView.addArrangedSubviews([thirdImageView, thirdLabel])
        mainStackView.addArrangedSubviews([firstStackView, secondStackView, thirdStackView])

        addSubviews(unrealLabel, mainStackView)
    }

    private func setupConstraints() {
        unrealLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(6)
        }

        mainStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(unrealLabel.snp.bottom).offset(20)
        }

        [firstImageView, secondImageView, thirdImageView].forEach { imageView in
            imageView.snp.makeConstraints { make in
                make.size.equalTo(18)
            }
        }
    }
}
