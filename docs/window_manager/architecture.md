# Architecture

DesktopHome owns one WindowManager instance and exposes it through Provider.
Applications register with the manager before the existing FloatingWindow
renderer displays them.

DesktopHome -> WindowManagerProvider -> WindowRegistry / FocusManager /
ZOrderManager / LifecycleManager / StateMachine.

The registry is the source of truth for lifecycle, focus and z-order metadata.
The existing renderer is preserved for visual behavior until later groups.