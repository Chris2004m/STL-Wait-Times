# Security Best Practices Report

Date: 2026-02-24
Project: `/Users/chris/Desktop/Personal Projects/STL Wait Times`

## Executive Summary
- Scope covered: transport security, outbound URL trust, external app handoff, permission surface, runtime logging exposure, and package/build artifact leakage.
- Result after remediation in this pass: no active critical findings.
- Resolved during this pass: 4 findings (`SEC-001` to `SEC-004`).
- Remaining risk: no open critical/high/medium issues from this pass.

## Critical Findings
- None identified after remediation.

## High Findings

### [SEC-001] Sensitive operational and location data could be exposed through runtime logs (Resolved)
- Severity: High
- Status: Resolved
- Risk: Raw `print(...)` logging included facility addresses, coordinates, and navigation/location runtime state, which can leak user-sensitive context through logs in production diagnostics/crash pipelines.
- Evidence/remediation references:
  - Added debug-only logging gate: `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times/Utils/DebugLog.swift:3`
  - Replaced direct logs in UI/services (examples):
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times/Views/DashboardView.swift:781`
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times/Services/LocationService.swift:222`
- Verification: repository search now finds no direct `print(...)` usage outside the debug logger implementation.

### [SEC-002] Outbound network calls lacked strict trust boundaries and session hardening (Resolved)
- Severity: High
- Status: Resolved
- Risk: Without strict URL host/scheme allowlisting and hardened URLSession behavior, malicious or malformed endpoint values could increase exposure to MITM/downgrade attempts or unintended data retention.
- Evidence/remediation references:
  - Enforced allowed host lists:
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times/Services/WaitTimeService.swift:23`
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times/Services/WaitTimeService.swift:28`
  - Enforced HTTPS + trusted host validation:
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times/Services/WaitTimeService.swift:416`
  - Hardened URLSession:
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times/Services/WaitTimeService.swift:73`
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times/Services/WaitTimeService.swift:81`
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times/Services/WaitTimeService.swift:82`
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times/Services/WaitTimeService.swift:83`
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times/Services/WaitTimeService.swift:89`

## Medium Findings

### [SEC-003] Permission scope exceeded minimum needed for current app behavior (Resolved)
- Severity: Medium
- Status: Resolved
- Risk: Extra permission declarations increase privacy surface and user trust burden.
- Remediation: Removed unused background/audio/speech/always-location declarations and kept `when-in-use` location only.
- Evidence/remediation references:
  - Current plist permissions:
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL-Wait-Times-Info.plist:6`
  - Build settings alignment (removed always-location key, kept when-in-use):
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times.xcodeproj/project.pbxproj:435`
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times.xcodeproj/project.pbxproj:468`

### [SEC-004] Backup/temp files could be unintentionally bundled into app artifacts (Resolved)
- Severity: Medium
- Status: Resolved
- Risk: Shipping backup/source artifact files can disclose internals or stale sensitive data.
- Remediation:
  - Deleted backup source file from app tree.
  - Added git ignore patterns and target-level source exclusions for backup/temp patterns.
- Evidence/remediation references:
  - Git ignore guards:
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/.gitignore:4`
  - Build-time exclusion:
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times.xcodeproj/project.pbxproj:431`
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times.xcodeproj/project.pbxproj:464`

## Low Findings

### [SEC-005] Mapbox token handling in source control (Resolved)
- Severity: Low
- Status: Resolved
- Risk: A hardcoded token in tracked files can be reused by unauthorized parties and can trigger repository push protection.
- Remediation:
  - Replaced hardcoded token with a build variable reference:
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL-Wait-Times-Info.plist:17`
  - Added explicit build setting key for local/CI injection:
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times.xcodeproj/project.pbxproj:445`
    - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times.xcodeproj/project.pbxproj:479`

## Additional Hardening Applied
- Phone URL sanitization before `tel://` launch:
  - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times/Views/FacilityDetailView.swift:353`
- Main-actor delegate isolation fix for navigation service concurrency warning:
  - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait Times/Services/AppleNavigationService.swift:254`

## Validation Performed
- Build: `xcodebuild ... build` succeeded.
- Static analysis: `xcodebuild ... analyze` succeeded.
- Tests: `xcodebuild ... -only-testing:'STL Wait TimesTests' test` failed due a pre-existing test syntax issue unrelated to this security pass:
  - `/Users/chris/Desktop/Personal Projects/STL Wait Times/STL Wait TimesTests/EnhancedScrollingIntegrationTests.swift:85`
