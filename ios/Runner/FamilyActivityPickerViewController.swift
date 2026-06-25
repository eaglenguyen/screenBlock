//
//  FamilyActivityPickerViewController.swift
//  Runner
//
//  Created by Egor on 5/18/26.
//

import UIKit
import SwiftUI
import FamilyControls

@available(iOS 16.0, *)
class FamilyActivityPickerViewController: UIViewController {

    private let service: IOSBlockingService
    private let onDismiss: () -> Void
    private let saveKey: String

    init(
        service: IOSBlockingService,
        onDismiss: @escaping () -> Void,
        saveKey: String = "blockedApps"
    ) {
        self.service = service
        self.onDismiss = onDismiss
        self.saveKey = saveKey
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
            saveKey: saveKey // 👈 pass through
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

    @State private var selection = FamilyActivitySelection()

    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Select Apps")
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
                        // 👈 remove the disabled condition entirely
                        // allow saving even with empty selection
                    }
                }
                .onAppear {
                    // load previously saved selection
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
