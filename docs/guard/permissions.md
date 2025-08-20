### Android
| Permission | Why | In‑App Disclosure |
|------------|-----|-------------------|
| PACKAGE_USAGE_STATS | Read app usage for Focus Score | "We analyse how long each app is open to calculate your Focus Score. Data never leaves your phone." |
| SYSTEM_ALERT_WINDOW | Overlay blocking screen | "Needed to gently block distracting apps during Focus sessions." |
| BIND_ACCESSIBILITY_SERVICE | Detect which app / text is on screen | "Lets Ta'aafi see which app is currently visible so it can block selected apps." |
| BIND_VPN_SERVICE | Local VPN for safe DNS | "Routes traffic through Ta'aafi's local filter to block known porn domains." |

### iOS
| Entitlement | Capability Tab | Usage |
|-------------|---------------|-------|
| com.apple.developer.networking.vpn.api | Personal VPN | DNS filter tunnel |
| com.apple.developer.networking.networkextension | Packet Tunnel / Filter Data Provider | On‑device request blocking |
| com.apple.developer.family-controls | Family Controls | Presents Apple picker & DeviceActivity reports |
