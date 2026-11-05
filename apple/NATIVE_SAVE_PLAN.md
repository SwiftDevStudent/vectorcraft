# Native Save activity scheduling — 2026-10-18

Tracking: `issue_01m5830rveszqsbjasthpp2s1y`. Full Mac parity remains active.

Installed rapid Copy/Paste/Save froze with the main thread waiting in NSDocument's
serialization semaphore; the synthetic file stayed unchanged on disk. A separate
Save after the editing event completed succeeded. Preserve the sample at
`/private/tmp/vectorcraft-fit-sample.txt` and avoid claiming slower saves prove a fix.

Replace SwiftUI's supported `saveItem` command group and route Save/Save As to the
current native NSDocument. Preserve Close/Close All, Duplicate, Rename, Move and native
revert/version actions. A responder bridge was not on the real built-in command path;
it was removed after runtime logging exposed the bypass.

Connect the native controller after application launch. Accessing its singleton during
Commands construction preempted SwiftUI's own controller and crashed a prototype's
cold launch; the final build passes cold launch. Refresh AppKit's recent-file projection
when a document becomes main; KVO alone left it stale in GUI checks. Only enable
Share when AppKit supplies an available action. Do not count disabled actions as parity.

Schedule with `performActivity(withSynchronousWaiting:false)`, enter the native
continuation with `continueActivity`, and invoke the standard native Save operation.
Retain the activity and its completion delegate through success, failure or cancellation.
Keep native file coordination, snapshots, dialogs and autosave ownership unchanged.
Do not add timing delays, swizzling, a shadow document or a parallel file writer.

The focused regression proves a pending activity prevents Save from running immediately
while the main actor can release that activity. Also check queued Save/Save As order
and completion lifetimes. Then verify the installed keyboard/menu path in app logs,
rapid edit/Save, inspector/inline focus, untitled Save/cancel/retry, Save As, Undo/Redo
and reopen. Broader native lifecycle stress remains part of P28/P35.

Source: the selected SDK's NSDocument.h activity/continuation contract and
[Apple's activity documentation](https://developer.apple.com/documentation/appkit/nsdocument/performactivity(withsynchronouswaiting:using:)).
