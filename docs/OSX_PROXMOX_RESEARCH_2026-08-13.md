# OSX-PROXMOX passive review — 2026-08-13

Source: https://github.com/luchina-gabriel/OSX-PROXMOX

The repository describes a procedure for running macOS as a virtual machine on a **fresh Proxmox VE 7–8 host**, covering Intel and AMD hardware. Its README explicitly instructs the operator to open the Proxmox Web Console shell and execute `/bin/bash -c "$(curl -fsSL https://install.osx-proxmox.com)"`. The repository contains `install.sh`, `EFI/`, `Artefacts/`, `tools/`, and `setup`; it is not a Docker image or a macOS container.

The repository claims support for macOS High Sierra through Sequoia and requires a host with a working TSC clock source for newer macOS versions. The README includes destructive/system-level operations such as BIOS, GRUB, EFI, SIP/Gatekeeper, and VM configuration changes. It also includes a disclaimer for development/student/testing purposes and does not provide a ready-to-run macOS CI runner for the current Linux sandbox.

Decision: do not execute the remote `curl | bash` installer or modify the sandbox host. The repository can be used only by the user on a separately provisioned Proxmox host, subject to the applicable Apple/Proxmox licensing and operational risks. For MiCoder, the required target is a real macOS runner with Xcode, SwiftUI, AppKit, WebKit, and the relevant signed app/runtime environment; Docker on Linux cannot supply those Apple frameworks.
