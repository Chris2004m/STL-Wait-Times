
# STL WaitLine — Product Requirements Document (PRD)

**Project Codename:** **STL WaitLine**  
**Target Platform:** Native iOS 17 + (SwiftUI)  
**Primary Dev Toolchain:** Cursor AI (code‑generation agent), Xcode, Swift Package Manager, Firebase CLI  

---

## 1. Purpose & Value

People with *non‑life‑threatening* issues often pick the nearest ED, only to discover multi‑hour waits. Urgent‑care centers sometimes have shorter queues, but their live stats are scattered across multiple corporate sites—or missing entirely. **STL WaitLine** collects and normalises three data classes (federal CMS averages, public urgent‑care JSON feeds, and real‑time crowd logs) so users can compare venues side‑by‑side and head to the shortest, clinically appropriate option.  
The MVP focuses on the St Louis metro to prove the model before scaling.

---

## 2. Goals & Non‑Goals

| Goals (MVP) | Explicit Non‑Goals |
| ----------- | ------------------ |
| • Let users see **two** independent wait indicators for every hospital ED (CMS quarterly average **plus** crowd‑sourced live). | • Triage life‑threatening emergencies (the app will *always* tell users to dial 911). |
| • Show minute‑level “patients in line / wait” values for urgent‑care chains that publish feeds. | • Provide *guaranteed* wait‑time accuracy; values are **estimates**. |
| • Provide a detail screen with 24 h trend, one‑tap directions, and in‑app “log my wait” (geo‑fenced). | • Deep clinical guidance (diagnosis, treatment advice). |
| • Respect HIPAA/PII boundaries—anonymous crowd IDs only. | • Android or web clients in phase 1. |

**Success metrics**

* **Accuracy delta** vs. on‑site signage ≤ ±20 min (80‑percentile).  
* **Week‑4 retention** ≥ 25 % for first‑wave testers.  
* **≥ 200** validated crowd submissions in the first 60 days.

---

## 3. Personas

1. **Erin, 29, Mild Asthma Flare** – wants the shortest safe venue tonight at 9 pm.  
2. **Tom & Kelly, Parents** – need to decide ED vs. urgent‑care for their child’s ear pain.  
3. **Dr. Patel, ED Medical Director** – interested in partnering to divert low‑acuity traffic away when saturated.

---

## 4. User Journeys

| Step | Erin (ED focus) | Tom & Kelly (UC focus) |
| ---- | --------------- | ---------------------- |
| 1 | Opens app → sees Facility List sorted by distance. | Opens app → toggles **Urgent‑care** list. |
| 2 | Notices ED A shows *CMS avg 140 min* + *Crowd live ≈ 60 min*. | Sees UC X: “Patients in line: 3 (≈ 15 min)”. |
| 3 | Taps ED A → Detail screen chart shows 3 h downward trend. | Taps UC X → Detail screen chart stable. |
| 4 | Starts driving; phone auto‑logs arrival, enabling “Log my wait”. | Books in‑app directions and calls ahead. |

---

## 5. Functional Requirements (MVP)

| # | Feature | Description & Acceptance Criteria |
| - | ------- | -------------------------------- |
| F‑1 | **Facility List View** | Toggle *ED* / *Urgent‑care*. Sorted by (a) distance, (b) shortest wait (user‑selectable). Each row shows: name, distance, CMS avg chip (EDs only), Crowd live chip (EDs), Live UC indicator (UCs). |
| F‑2 | **Dual Wait Indicators (EDs)** | • *CMS avg* from OP‑22/OP‑20.  
• *Crowd live* = weighted mean of logs ≤ 2 h old (age‑decay). |
| F‑3 | **Live UC Indicator** | Pull JSON/XHR feed every 60 s (respect rate limits). Display “Patients: N” or “Wait: X min”. |
| F‑4 | **Detail Screen** | • 24 h line chart (SwiftUI Charts).  
• Button “Log my wait” appears when CoreLocation detects radius ≤ 75 m for ≥ 5 min.  
• Shortcuts: Apple Maps directions, Tap‑to‑Call. |
| F‑5 | **Background Refresh** | `BGAppRefreshTask` every 120 s; fetch UC feeds + push deltas to Firestore cache. |
| F‑6 | **Disclaimers & Safety** | Persistent banner: *“Times are estimates. If you think you’re having an emergency, call 911.”* |
| F‑7 | **On‑Device Anonymised Logging** | When user taps “Log my wait”, app stores: hash(deviceID + day), facilityID, check‑in ts, provider‑seen ts. Data syncs to Firestore in anonymous mode. |

---

## 6. Non‑Functional Requirements

| Area | Requirement |
| ---- | ----------- |
| Performance | List view initial load ≤ 800 ms on iPhone 12. Background fetch CPU ≤ 100 ms per cycle. |
| Privacy | No PII collected; HIPAA‑adjacent data processed on‑device or in HIPAA‑exempt Firestore anonymous mode. |
| Reliability | 99.5 % crash‑free sessions. Offline mode shows last‑fetched data; stale badge if > 8 h. |
| Compliance | Meets Apple *Health & Medical* guidelines; prominent disclaimers. |
| Accessibility | Dynamic Type, VoiceOver, ≥ 4.5:1 contrast. |
| Security | Firestore rules: public read‑only, write‑only with validation. CMS JSON bundled & code‑signed. |

---

## 7. Data Architecture

| Source | Storage / Access | Refresh Cadence |
| ------ | --------------- | --------------- |
| CMS OP‑22/OP‑20 | Parsed offline → bundled `cms_ed_baseline.json`. | 90 days (App Store updates). |
| Public UC feeds | Cloud Function fetcher → `uc_live/{facility}` in Firestore. | 60 s cron (cache‑control). |
| Crowd logs | App writes to `crowd_logs/{day}/{facility}`. Cloud Function aggregates → `crowd_live/{facility}`. | Real‑time on write |

**Crowd weight formula**

```
weight = max(0, 1 – (t_now – t_log) ⁄ 7200)   # linear decay to 0 after 2 h
```

---

## 8. Technical Stack Snapshot

* **Client:** Swift 5.10, SwiftUI 3, Combine, MapKit, SwiftUI Charts  
* **Data:** Firebase Firestore (free tier) & Firebase Functions (Node 20)  
* **Location:** CoreLocation & geo‑fencing (`CLRegion`)  
* **Background:** `BGAppRefreshTask`, `BGProcessingTask`  
* **Analytics:** Firebase Analytics (`wait_accuracy_delta` event)  
* **CI/CD:** Xcode Cloud → TestFlight → App Store  
* **Cursor AI Rules**  
  * *Tech‑Stack Rule* – generate SwiftUI, MVVM, lint w/ SwiftLint.  
  * *Error‑Containment* – auto‑run unit + snapshot tests; abort on fail.  
  * *Hallucination Guard* – require inline docs that cite Apple API; reject “magic” APIs.

---

## 9. Milestones & Timeline (90‑day Alpha)

| Week | Milestone | Owner |
| ---- | --------- | ----- |
| 1‑2 | Repo, Firestore schema, CMS ingestion script. | Lead Dev |
| 3‑4 | Facility List UI + distance sort. | iOS Eng |
| 5‑6 | UC feed fetcher + BG refresh. | Backend |
| 7‑8 | Crowd logging flow + rules. | Full‑stack |
| 9‑10 | Detail screen + geo‑fenced logging. | iOS Eng |
| 11 | Accessibility & localisation. | QA |
| 12 | Beta Test (TestFlight 0.9). | PM |
| 13 | Bug‑fix, analytics, App Review. | All |

---

## 10. Risks & Mitigations

| Risk | Impact | Mitigation |
| ---- | ------ | ---------- |
| Low crowd volume → inaccurate live waits. | Medium | Seed entries; gamify first 5 logs/week. |
| UC feeds block/limit. | Medium | Cache 60 s; negotiate APIs. |
| Misinterpretation in emergencies. | High | onboarding + persistent 911 disclaimers. |
| Firestore read costs at scale. | Low (alpha) | Use aggregated docs only. |

---

## 11. Open Questions

1. Do BJC/SSM hospitals expose any HL7/FHIR wait endpoints we can test?  
2. Which copy drives more logs: “Log your door‑to‑provider time” vs. “Help neighbors—share your wait”?  
3. Can OP‑22 acuity breakouts be obtained to weight averages?

---

## 12. Future Expansion Paths

* **Geo Scale‑Up** – replicate to Chicago, KC, etc.  
* **Push Alerts** – “Wait spike at your starred facility.”  
* **Hospital Feeds** – direct HL7/FHIR for official live ED trackers.  
* **Insurance Integration** – in‑network flags via Apple HealthPlan (post‑MVP).

---

### Appendix

**CMS JSON schema**

```json
{
  "facility_id": "260122",
  "name": "Barnes‑Jewish Hospital",
  "city": "St Louis",
  "cms_avg_wait_min": 137
}
```

**Crowd Log doc (`crowd_logs/2025‑07‑11/260122/{log}`)**

```json
{
  "anon_id_hash": "4a7…",
  "check_in": 1703733600,
  "seen_at": 1703737800,
  "posted_at": 1703741400,
  "device_uptime": 522
}
```

**Example UC feed**

`https://api.gohealthuc.com/v1/clinics/123/waittime → {"patientsInLine":3,"estimatedWait":15}`

---

*Last updated: 2025‑07‑11*
