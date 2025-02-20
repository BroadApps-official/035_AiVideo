import AVFoundation
import UIKit

final class CreativesCell: UICollectionViewCell {
    static let identifier = "CreativesCell"
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        label.do { make in
            make.text = L.creatives
            make.font = UIFont.CustomFont.title2Emphasized
            make.textAlignment = .left
            make.textColor = UIColor.labelsSecondary
        }

        contentView.addSubview(label)

        label.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
        }
    }
}
