//
//  DeviceActivityReportViewFactory.swift
//  Runner
//

import Flutter
import UIKit
import SwiftUI
import DeviceActivity
import FamilyControls

class DeviceActivityReportViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
        FocusLogger.d("🟠 [REPORT FACTORY] === init: factory created ===")
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        FocusLogger.d("🟠 [REPORT FACTORY] === create: START === viewId=\(viewId), frame=\(frame)")
        let view = DeviceActivityReportFlutterView(frame: frame, viewId: viewId, messenger: messenger, args: args)
        FocusLogger.d("🟠 [REPORT FACTORY] === create: END ===")
        return view
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class DeviceActivityReportFlutterView: NSObject, FlutterPlatformView {
    private let _view: UIView
    private let _viewId: Int64
    
    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
        _view = UIView(frame: frame)
        _viewId = viewId
        super.init()
        
        FocusLogger.d("🟠 [REPORT VIEW] === init: START === viewId=\(_viewId)")
        FocusLogger.d("🟠 [REPORT VIEW] init: frame=\(frame)")
        if let args = args {
            FocusLogger.d("🟠 [REPORT VIEW] init: args=\(args)")
        }
        
        createReportView()
        FocusLogger.d("🟠 [REPORT VIEW] === init: END ===")
    }
    
    func view() -> UIView {
        return _view
    }
    
    private func createReportView() {
        FocusLogger.d("🟠 [REPORT VIEW] === createReportView: START ===")
        
        // Create the DeviceActivityReport with SwiftUI
        FocusLogger.d("🟠 [REPORT VIEW] createReportView: instantiating ActivityReportContainerView")
        let reportView = ActivityReportContainerView()
        let hostingController = UIHostingController(rootView: reportView)
        
        FocusLogger.d("🟠 [REPORT VIEW] createReportView: configuring hosting controller")
        // Add as subview
        hostingController.view.frame = _view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.view.backgroundColor = .clear
        
        FocusLogger.d("🟠 [REPORT VIEW] createReportView: adding to view hierarchy")
        _view.addSubview(hostingController.view)
        
        FocusLogger.d("🟠 [REPORT VIEW] createReportView: ✅ report view created and added")
        FocusLogger.d("🟠 [REPORT VIEW] === createReportView: END ===")
    }
}

struct ActivityReportContainerView: View {
    @State private var context = DeviceActivityReport.Context.totalActivity
    @State private var filter = DeviceActivityFilter(
        segment: .daily(during: Calendar.current.dateInterval(of: .day, for: Date())!),
        users: .all,
        devices: .init([.iPhone, .iPad])
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // Embed the DeviceActivityReport
            DeviceActivityReport(context, filter: filter)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            FocusLogger.d("🟠 [REPORT CONTAINER] === onAppear: START ===")
            // Update filter to today's date
            let today = Calendar.current.dateInterval(of: .day, for: Date())!
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            FocusLogger.d("🟠 [REPORT CONTAINER] onAppear: today's interval - start=\(formatter.string(from: today.start)), end=\(formatter.string(from: today.end))")
            
            filter = DeviceActivityFilter(
                segment: .daily(during: today),
                users: .all,
                devices: .init([.iPhone, .iPad])
            )
            FocusLogger.d("🟠 [REPORT CONTAINER] onAppear: ✅ filter updated to today")
            FocusLogger.d("🟠 [REPORT CONTAINER] === onAppear: END ===")
        }
    }
}

