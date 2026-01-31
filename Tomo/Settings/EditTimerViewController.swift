import AppKit

class EditTimerViewController: NSViewController {
    private var config: TimerConfig
    private let contentRoot = ContentRootView()

    init(config: TimerConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    private var editBgColor: NSColor {
        let base = config.color.nsColor
        // HSL: lightness 0.3, saturation 0.2
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        (base.usingColorSpace(.sRGB) ?? base).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return NSColor(hue: h, saturation: 0.2, brightness: 0.35, alpha: 1)
    }

    override func loadView() {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = editBgColor.cgColor

        // App bar
        let appBar = NSView()
        appBar.translatesAutoresizingMaskIntoConstraints = false
        appBar.wantsLayer = true
        appBar.layer?.backgroundColor = editBgColor.cgColor
        container.addSubview(appBar)
        appBar.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        appBar.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        appBar.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        appBar.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let backBtn = makeNavButton(systemName: "chevron.left", tooltip: "Back") { [weak self] in
            self?.view.window?.contentViewController = SettingsViewController()
        }
        appBar.addSubview(backBtn)
        backBtn.leadingAnchor.constraint(equalTo: appBar.leadingAnchor, constant: 8).isActive = true
        backBtn.centerYAnchor.constraint(equalTo: appBar.centerYAnchor).isActive = true

        let title = NSTextField(labelWithString: "Timer settings")
        title.font = .systemFont(ofSize: 20, weight: .medium)
        title.textColor = .white
        title.translatesAutoresizingMaskIntoConstraints = false
        appBar.addSubview(title)
        title.centerXAnchor.constraint(equalTo: appBar.centerXAnchor).isActive = true
        title.centerYAnchor.constraint(equalTo: appBar.centerYAnchor).isActive = true

        contentRoot.hasAppBar = true
        container.addSubview(contentRoot)
        contentRoot.topAnchor.constraint(equalTo: appBar.bottomAnchor).isActive = true
        contentRoot.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        contentRoot.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        contentRoot.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true

        self.view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        rebuild()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        contentRoot.updateWindowHeight()
    }

    private func rebuild() {
        var views: [NSView] = []

        // Name field
        let nameField = AutoSelectTextField()
        nameField.stringValue = config.name
        nameField.placeholderString = "Name"
        nameField.font = .systemFont(ofSize: 16)
        nameField.textColor = .white
        nameField.backgroundColor = .clear
        nameField.isBezeled = true
        nameField.bezelStyle = .roundedBezel
        nameField.onTextChanged = { [weak self] text in
            self?.config.name = text
            self?.saveConfig()
        }
        views.append(makeLabeledField("Name", field: nameField))
        views.append(makeSpacer(20))

        // Duration editor
        views.append(EditDurationView(duration: config.duration) { [weak self] duration in
            self?.config.duration = duration
            self?.saveConfig()
        })
        views.append(makeSpacer(20))

        // Color picker
        views.append(ColorPickerView(selected: config.color) { [weak self] color in
            self?.config.color = color
            self?.saveConfig()
            self?.updateBackground()
        })
        views.append(makeSpacer(20))

        // Sound picker
        views.append(SoundPickerView(selected: config.sound) { [weak self] sound in
            self?.config.sound = sound
            self?.saveConfig()
        })
        views.append(makeSpacer(20))

        // Start next dropdown
        let startNextView = makeStartNextDropdown()
        views.append(startNextView)
        views.append(makeSpacer(30))

        // Delete button
        let deleteBtn = ActionButton()
        deleteBtn.leftView = makeIconView(systemName: "trash", color: grayTextColor)
        let deleteLabel = NSTextField(labelWithString: "Delete timer")
        deleteLabel.font = .systemFont(ofSize: 16, weight: .medium)
        deleteLabel.textColor = grayTextColor
        deleteBtn.centerView = deleteLabel
        deleteBtn.onPressed = { [weak self] in
            AppState.shared.deleteTimer(self!.config)
            self?.view.window?.contentViewController = SettingsViewController()
        }
        views.append(deleteBtn)

        contentRoot.setChildren(views)
    }

    private func saveConfig() {
        AppState.shared.updateTimerConfig(config)
    }

    private func updateBackground() {
        view.layer?.backgroundColor = editBgColor.cgColor
        // Update appbar too
        if let appBar = view.subviews.first(where: { $0 !== contentRoot }) {
            appBar.layer?.backgroundColor = editBgColor.cgColor
        }
    }

    private func makeLabeledField(_ label: String, field: NSTextField) -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4

        let lbl = NSTextField(labelWithString: label)
        lbl.font = .systemFont(ofSize: 12, weight: .medium)
        lbl.textColor = labelTextColor
        stack.addArrangedSubview(lbl)
        stack.addArrangedSubview(field)
        field.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        return stack
    }

    private func makeStartNextDropdown() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4

        let lbl = NSTextField(labelWithString: "Start next")
        lbl.font = .systemFont(ofSize: 12, weight: .medium)
        lbl.textColor = labelTextColor
        stack.addArrangedSubview(lbl)

        let popup = NSPopUpButton()
        popup.translatesAutoresizingMaskIntoConstraints = false

        popup.addItem(withTitle: "Nothing")
        popup.lastItem?.representedObject = nil

        for cfg in AppState.shared.timerConfigs {
            popup.addItem(withTitle: cfg.name)
            popup.lastItem?.representedObject = cfg.id as NSString
        }

        // Select current
        if let nextId = config.startNextId {
            for i in 0..<popup.numberOfItems {
                if let obj = popup.item(at: i)?.representedObject as? String, obj == nextId {
                    popup.selectItem(at: i)
                    break
                }
            }
        }

        let helper = ButtonActionHelper { [weak self, weak popup] in
            let selectedId = popup?.selectedItem?.representedObject as? String
            self?.config.startNextId = selectedId
            self?.saveConfig()
        }
        popup.target = helper
        popup.action = #selector(ButtonActionHelper.invoke)
        objc_setAssociatedObject(popup, "helper", helper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        stack.addArrangedSubview(popup)
        popup.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        return stack
    }
}
