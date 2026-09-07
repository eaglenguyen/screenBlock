//
//  FamilyActivityPickerViewController.swift
//  Runner
//
import UIKit
import SwiftUI
import FamilyControls

@available(iOS 16.0, *)
class FamilyActivityPickerViewController: UIViewController {
    private let service: IOSBlockingService
    private let onDismiss: () -> Void
    private let saveKey: String
    private let pickerTitle: String
    private let requireSelection: Bool // 👈 new

    init(
        service: IOSBlockingService,
        onDismiss: @escaping () -> Void,
        saveKey: String = "blockedApps",
        pickerTitle: String = "Select Apps",
        requireSelection: Bool = false // 👈 new
    ) {
        self.service = service
        self.onDismiss = onDismiss
        self.saveKey = saveKey
        self.pickerTitle = pickerTitle
        self.requireSelection = requireSelection // 👈 new
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let pickerView = FamilyActivityPickerView(
            service: service,
            onDismiss: { [weak self] in
                self?.dismiss(animated: true) {
                    self?.onDismiss()
                }
            },
            saveKey: saveKey,
            title: pickerTitle,
            requireSelection: requireSelection // 👈 new
        )
        let hostingController = UIHostingController(
            rootView: pickerView
        )
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight
        ]
        hostingController.didMove(toParent: self)
    }
}



@available(iOS 16.0, *)
struct FamilyActivityPickerView: View {
    let service: IOSBlockingService
    let onDismiss: () -> Void
    let saveKey: String
    let title: String
    let requireSelection: Bool // 👈 new — defaults false to preserve existing pickers' behavior
    @State private var selection = FamilyActivitySelection()

    init(
        service: IOSBlockingService,
        onDismiss: @escaping () -> Void,
        saveKey: String,
        title: String,
        requireSelection: Bool = false // 👈 new
    ) {
        self.service = service
        self.onDismiss = onDismiss
        self.saveKey = saveKey
        self.title = title
        self.requireSelection = requireSelection
    }

    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            onDismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            service.saveAppSelection(
                                selection,
                                forKey: saveKey
                            )
                            print("🦅 saved \(selection.applicationTokens.count) tokens")
                            onDismiss()
                        }
                        .fontWeight(.semibold)
                        .disabled(requireSelection && selection.applicationTokens.isEmpty) // 👈 new
                    }
                }
                .onAppear {
                    loadSavedSelection()
                }
        }
        .accentColor(Color(
            red: 237/255,
            green: 184/255,
            blue: 42/255
        ))
    }

    private func loadSavedSelection() {
        guard let defaults = UserDefaults(
            suiteName: "group.com.eagle.pausenow"
        ) else {
            print("🦅 no shared defaults available")
            return
        }
        guard let data = defaults.data(forKey: saveKey) else {
            print("🦅 no saved selection for key: \(saveKey)")
            return
        }
        do {
            let saved = try JSONDecoder().decode(
                FamilyActivitySelection.self,
                from: data
            )
            selection = saved
            print("🦅 loaded \(saved.applicationTokens.count) saved tokens")
        } catch {
            print("🦅 failed to load saved selection: \(error)")
        }
    }
}
