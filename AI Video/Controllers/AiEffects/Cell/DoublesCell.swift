import AVFoundation
import UIKit

final class DoublesCell: UICollectionViewCell {
    static let identifier = "DoublesCell"
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
            make.text = L.doubles
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
