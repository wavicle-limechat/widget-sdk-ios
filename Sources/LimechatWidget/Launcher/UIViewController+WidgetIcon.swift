import UIKit

public extension UIViewController {
    
    /// Add a floating widget icon to the view controller
    /// - Parameters:
    ///   - configuration: Widget configuration
    ///   - delegate: Widget delegate
    ///   - position: Position of the icon (default: bottom right)
    ///   - customIcon: Custom icon image (optional)
    func addWidgetIcon(
        configuration: WidgetConfiguration,
        delegate: LimechatWidgetDelegate? = nil,
        position: WidgetIconPosition = .bottomRight,
        customIcon: UIImage? = nil
    ) -> LimechatWidgetIcon {
        
        let icon = LimechatWidgetIcon()
        icon.delegate = delegate
        icon.customIcon = customIcon
        icon.initialize(with: configuration)
        
        view.addSubview(icon)
        
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        let safeArea = view.safeAreaLayoutGuide
        var constraints = [
            icon.widthAnchor.constraint(equalToConstant: icon.iconSize),
            icon.heightAnchor.constraint(equalToConstant: icon.iconSize)
        ]
        switch position {
        case .bottomRight, .bottomLeft:
            constraints.append(icon.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -20))
        case .topRight, .topLeft:
            constraints.append(icon.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 20))
        }
        switch position {
        case .bottomRight, .topRight:
            constraints.append(icon.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20))
        case .bottomLeft, .topLeft:
            constraints.append(icon.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20))
        }
        NSLayoutConstraint.activate(constraints)
        
        return icon
    }
}
