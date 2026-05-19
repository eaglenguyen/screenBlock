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
    
    init(
        service: IOSBlockingService,
        onDismiss: @escaping () -> Void
    ) {
        self.service = service
        self.onDismiss = onDismiss
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
            }
        )
        
        let hostingController = UIHostingController(
            rootView: pickerView
        )
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [
            .flexibleWidth, .flexibleHeight
        ]
        hostingController.didMove(toParent: self)
    }
}

@available(iOS 16.0, *)
struct FamilyActivityPickerView: View {
    
    let service: IOSBlockingService
    let onDismiss: () -> Void
    
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
                                forKey: "blockedApps"
                            )
                            onDismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
        }
        .accentColor(Color(
            red: 237/255,
            green: 184/255,
            blue: 42/255
        ))
    }
}
