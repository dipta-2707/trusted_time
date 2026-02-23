# Changelog

All notable changes to this project will be documented in this file.

The format is based on **Keep a Changelog**, and this project follows **Semantic Versioning**.

---

## [1.0.0] - 2026-02-23

### ✨ Initial Release

#### Added

* Tamper-resistant trusted time service.
* Secure UTC time fetching from a trusted HTTPS source.
* Native monotonic uptime anchoring using FFI.
* Trusted UTC and offset-based local time calculation.
* Manual trusted time anchor support.
* Default timezone offset configuration.
* Safe fallback to system time when initialization fails.
* Reset mechanism to clear trusted anchor.
* Android and iOS support out of the box.


---

## How to update this file

When releasing a new version:

1. Add release date.
2. Describe changes clearly.
3. Follow semantic versioning:

    * **MAJOR**: Breaking changes.
    * **MINOR**: New features.
    * **PATCH**: Bug fixes.

Example:

```
## [1.1.0] - YYYY-MM-DD
### Added
- New feature.

### Fixed
- Bug fix.
```
