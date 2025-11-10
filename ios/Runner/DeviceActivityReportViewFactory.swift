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
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return DeviceActivityReportFlutterView(frame: frame, viewId: viewId, messenger: messenger, args: args)
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class DeviceActivityReportFlutterView: NSObject, FlutterPlatformView {
    private let _view: UIView
    
    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
        _view = UIView(frame: frame)
        super.init()
        
        createReportView()
    }
    
    func view() -> UIView {
        return _view
    }
    
    private func createReportView() {
        FocusLogger.d("=== DeviceActivityReportView: creating report ===")
        
        // Create the DeviceActivityReport with SwiftUI
        let reportView = ActivityReportContainerView()
        let hostingController = UIHostingController(rootView: reportView)
        
        // Add as subview
        hostingController.view.frame = _view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.view.backgroundColor = .clear
        
        _view.addSubview(hostingController.view)
        
        FocusLogger.d("=== DeviceActivityReportView: report created ===")
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
            FocusLogger.d("ActivityReportContainerView: onAppear")
            // Update filter to today's date
            let today = Calendar.current.dateInterval(of: .day, for: Date())!
            filter = DeviceActivityFilter(
                segment: .daily(during: today),
                users: .all,
                devices: .init([.iPhone, .iPad])
            )
        }
    }
}

