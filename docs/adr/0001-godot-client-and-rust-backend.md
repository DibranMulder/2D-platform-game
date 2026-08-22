# Use a Godot client and a separate Rust backend

The game uses Godot 4 for the cross-platform GPU client and Rust for authoritative
backend modules. Godot provides one exportable 2D client across macOS, iPadOS,
Windows, and Android with Vulkan, Direct3D 12, and Metal rendering paths; Rust
provides a memory-safe, headless backend without coupling world rules to a scene
tree. This costs us a language boundary, which is kept at the versioned wire
contract rather than duplicated inside gameplay rules.

