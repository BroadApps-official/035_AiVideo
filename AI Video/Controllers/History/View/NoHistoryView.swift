import SnapKit
import UIKit

final class NoHistoryView: UIControl {
    private let imageView = UIImageView()
    private let firstLabel = UILabel()
    private let secondLabel = UILabel()

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

        imageView.image = UIImage(named: "no_history_icon")
        firstLabel.do { make in
            make.text = L.emptyHere
            make.font = UIFont.CustomFont.title3Emphasized
            make.textAlignment = .center
            make.textColor = UIColor.labelsPrimary
        }

        secondLabel.do { make in
            make.text = L.createFirstGeneration
            make.font = UIFont.CustomFont.footnoteRegular
            make.textAlignment = .center
            make.textColor = UIColor.labelsSecondary
            make.numberOfLines = 0
        }

        addSubviews(imageView, firstLabel, secondLabel)
    }

    private func setupConstraints() {
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(64)
        }

        firstLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
            make.height.equalTo(25)
        }

        secondLabel.snp.makeConstraints { make in
            make.top.equalTo(firstLabel.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
            make.width.equalTo(280)
        }
    }
}
