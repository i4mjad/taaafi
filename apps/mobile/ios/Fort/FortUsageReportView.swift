import Flutter
import UIKit
import SwiftUI
import DeviceActivity

/// Factory that registers a Flutter platform view embedding the
/// DeviceActivityReport SwiftUI view. When this view appears on screen,
/// iOS calls the DeviceActivityReportExtension's makeConfiguration,
/// which writes usage data to the shared app group UserDefaults.
@available(iOS 16.0, *)
class FortUsageReportViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FortUsageReportPlatformView(frame: frame)
    }
}

@available(iOS 16.0, *)
class FortUsageReportPlatformView: NSObject, FlutterPlatformView {
    private let hostingController: UIHostingController<DeviceActivityReport>

    init(frame: CGRect) {
        let filter = DeviceActivityFilter(
            segment: .daily(
                during: DateInterval(
                    start: Calendar.current.startOfDay(for: Date()),
                    end: Date()
                )
            )
        )
        let report = DeviceActivityReport(
            DeviceActivityReport.Context("Total Activity"),
            filter: filter
        )
        hostingController = UIHostingController(rootView: report)
        hostingController.view.frame = frame
        hostingController.view.backgroundColor = .clear
        super.init()
    }

    func view() -> UIView {
        return hostingController.view
    }
}
