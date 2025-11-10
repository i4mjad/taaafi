//
//  DeviceActivityReportViewFactory.swift
//  Runner
//
//  Flutter Platform View factory for embedding DeviceActivityReport in Flutter UI
//  This bridges the SwiftUI DeviceActivityReport with Flutter's widget tree
//

import Flutter
import UIKit
import SwiftUI
import DeviceActivity
import FamilyControls

// MARK: - Platform View Factory

/// Factory class that creates platform views for Flutter
/// Implements FlutterPlatformViewFactory to integrate iOS views into Flutter
class DeviceActivityReportViewFactory: NSObject, FlutterPlatformViewFactory {
    /// Flutter binary messenger for communication
    private let messenger: FlutterBinaryMessenger
    
    /// Initializes the factory with Flutter's messenger
    /// - Parameter messenger: Binary messenger for method channel communication
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
        FocusLogger.d("🟠 [REPORT FACTORY] === init: factory created ===")
    }
    
    /// Creates a new platform view instance when Flutter requests it
    /// Called by Flutter when UiKitView widget is built
    ///
    /// - Parameters:
    ///   - frame: Initial frame for the view
    ///   - viewId: Unique identifier assigned by Flutter
    ///   - args: Optional arguments passed from Flutter (unused for this view)
    /// - Returns: FlutterPlatformView instance containing the report
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        FocusLogger.d("🟠 [REPORT FACTORY] === create: START === viewId=\(viewId), frame=\(frame)")
        let view = DeviceActivityReportFlutterView(
            frame: frame,
            viewId: viewId,
            messenger: messenger,
            args: args
        )
        FocusLogger.d("🟠 [REPORT FACTORY] === create: END ===")
        return view
    }
    
    /// Returns the message codec for encoding/decoding arguments
    /// Uses standard codec for simple types
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

// MARK: - Platform View Implementation

/// Flutter platform view that wraps the DeviceActivityReport
/// Implements FlutterPlatformView protocol to integrate with Flutter
class DeviceActivityReportFlutterView: NSObject, FlutterPlatformView {
    /// The UIView that Flutter will embed in its widget tree
    private let _view: UIView
    
    /// View identifier assigned by Flutter
    private let _viewId: Int64
    
    /// Initializes the platform view and creates the report view
    ///
    /// - Parameters:
    ///   - frame: Initial frame for the view
    ///   - viewId: Unique identifier from Flutter
    ///   - messenger: Binary messenger for communication
    ///   - args: Optional arguments from Flutter
    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
        _view = UIView(frame: frame)
        _viewId = viewId
        super.init()
        
        FocusLogger.d("🟠 [REPORT VIEW] === init: START === viewId=\(_viewId)")
        FocusLogger.d("🟠 [REPORT VIEW] init: frame=\(frame)")
        if let args = args {
            FocusLogger.d("🟠 [REPORT VIEW] init: args=\(args)")
        }
        
        // Create and embed the SwiftUI report view
        createReportView()
        
        FocusLogger.d("🟠 [REPORT VIEW] === init: END ===")
    }
    
    /// Returns the UIView to Flutter for embedding
    /// Flutter calls this to get the native view to display
    func view() -> UIView {
        return _view
    }
    
    /// Creates the DeviceActivityReport SwiftUI view and embeds it in UIKit view
    /// Uses UIHostingController to bridge SwiftUI to UIKit
    private func createReportView() {
        FocusLogger.d("🟠 [REPORT VIEW] === createReportView: START ===")
        
        // Create the SwiftUI container view
        FocusLogger.d("🟠 [REPORT VIEW] createReportView: instantiating ActivityReportContainerView")
        let reportView = ActivityReportContainerView()
        
        // Wrap SwiftUI view in UIHostingController to use in UIKit
        let hostingController = UIHostingController(rootView: reportView)
        
        FocusLogger.d("🟠 [REPORT VIEW] createReportView: configuring hosting controller")
        
        // Configure the hosting controller's view to fill the container
        hostingController.view.frame = _view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.view.backgroundColor = .clear
        
        // Add to view hierarchy
        FocusLogger.d("🟠 [REPORT VIEW] createReportView: adding to view hierarchy")
        _view.addSubview(hostingController.view)
        
        FocusLogger.d("🟠 [REPORT VIEW] createReportView: ✅ report view created and added")
        FocusLogger.d("🟠 [REPORT VIEW] === createReportView: END ===")
    }
}

// MARK: - Report Container View

/// SwiftUI container that wraps the DeviceActivityReport framework component
/// Manages the report context and filter settings
struct ActivityReportContainerView: View {
    /// Context identifying which report scene to use
    /// Must match the context defined in TotalActivityReport ("Total Activity")
    @State private var context = DeviceActivityReport.Context("Total Activity")
    
    /// Filter specifying what data to show (date range, users, devices)
    /// Configured to show today's data for all users on iPhone/iPad
    @State private var filter = DeviceActivityFilter(
        segment: .daily(during: Calendar.current.dateInterval(of: .day, for: Date())!),
        users: .all,
        devices: .init([.iPhone, .iPad])
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Embedded DeviceActivityReport
            // This is the framework-provided component that connects to the report extension
            // It automatically calls our TotalActivityReport.makeConfiguration() method
            DeviceActivityReport(context, filter: filter)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            FocusLogger.d("🟠 [REPORT CONTAINER] === onAppear: START ===")
            
            // Update filter to today's date interval
            // This ensures we're always showing current day's data
            let today = Calendar.current.dateInterval(of: .day, for: Date())!
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            FocusLogger.d("🟠 [REPORT CONTAINER] onAppear: today's interval - start=\(formatter.string(from: today.start)), end=\(formatter.string(from: today.end))")
            
            // Update the filter with today's date
            filter = DeviceActivityFilter(
                segment: .daily(during: today),
                users: .all,  // Show data for all users
                devices: .init([.iPhone, .iPad])  // Show data from iPhone and iPad
            )
            
            FocusLogger.d("🟠 [REPORT CONTAINER] onAppear: ✅ filter updated to today")
            FocusLogger.d("🟠 [REPORT CONTAINER] === onAppear: END ===")
        }
    }
}
