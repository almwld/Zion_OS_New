# Zion OS Window Manager

The Window Manager is the central state owner for desktop windows. The existing
FloatingWindow UI remains the renderer; this layer owns identity, lifecycle,
focus and z-order.

## Group 1
- Registry
- Focus management
- Z-order
- Lifecycle/state machine
- Open/close/focus/raise operations
- Provider integration

Move, resize, snap, Alt+Tab and workspace orchestration remain later groups.