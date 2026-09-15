import SwiftUI
import FamilyControls
import Flutter

struct EmbeddedFamilyPickerView: View {
    @State private var selection = FamilyActivitySelection()
    let onSelectionChanged: (Int) -> Void
    let saveKey: String

    init(saveKey: String, onSelectionChanged: @escaping (Int) -> Void) {
        self.saveKey = saveKey
        self.onSelectionChanged = onSelectionChanged
        if let data = UserDefaults(suiteName: "group.com.eagle.pausenow")?.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            _selection = State(initialValue: decoded)
        }
    }

    var body: some View {
        FamilyActivityPicker(selection: $selection)
            .onChange(of: selection) { newValue in
                if let encoded = try? JSONEncoder().encode(newValue) {
                    UserDefaults(suiteName: "group.com.eagle.pausenow")?.set(encoded, forKey: saveKey)
                }
                let count = newValue.applicationTokens.count
                onSelectionChanged(count)
            }
    }
}

class EmbeddedAppPickerViewController: UIViewController {
    private let saveKey: String
    var onCountChanged: ((Int) -> Void)?

    init(saveKey: String) {
        self.saveKey = saveKey
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let swiftUIView = EmbeddedFamilyPickerView(saveKey: saveKey) { [weak self] count in
            self?.onCountChanged?(count)
        }
        let hosting = UIHostingController(rootView: swiftUIView)
        addChild(hosting)
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
    }
}

class EmbeddedAppPickerPlatformView: NSObject, FlutterPlatformView, FlutterStreamHandler {
    private let controller: EmbeddedAppPickerViewController
    private let eventChannel: FlutterEventChannel

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        let params = args as? [String: Any]
        let saveKey = params?["saveKey"] as? String ?? "embeddedAppPicker_default"

        eventChannel = FlutterEventChannel(
            name: "com.eagle.pausenow/embedded_app_picker_events_\(viewId)",
            binaryMessenger: messenger
        )
        controller = EmbeddedAppPickerViewController(saveKey: saveKey)

        super.init()

        eventChannel.setStreamHandler(self)
    }

    func view() -> UIView {
        return controller.view
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        controller.onCountChanged = { count in
            DispatchQueue.main.async {
                events(count)
            }
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        controller.onCountChanged = nil
        return nil
    }
}

class EmbeddedAppPickerPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return EmbeddedAppPickerPlatformView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
