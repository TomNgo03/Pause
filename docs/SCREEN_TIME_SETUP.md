# Screen Time Integration Setup

The repository runs in Prototype Mode by default. Full Screen Time support requires a paid Apple Developer team, capability configuration, full Xcode, and physical-device testing.

## Setup checklist

1. Create explicit bundle identifiers for the app and required extensions.
2. Create an App Group and replace `group.org.pauseproject.shared` everywhere with the registered identifier.
3. Request and enable the Family Controls entitlement for distribution.
4. Add Family Controls and App Groups capabilities to relevant targets and attach `Pause/Resources/Pause.entitlements` to the app target.
5. Add `PAUSE_SCREEN_TIME` to Active Compilation Conditions for device builds.
6. Add a Device Activity Monitor Extension target using `ScreenTimeExtensions/DeviceActivityMonitorExtension.swift`; set its principal class to `$(PRODUCT_MODULE_NAME).PauseDeviceActivityMonitor` and give it the same App Group and Family Controls capabilities.
7. Verify authorization, selection, shield application, session unlock, and reshielding on a physical iPhone.
8. Test permission revocation and device restart.

Never use private APIs or Accessibility workarounds to intercept other applications.
