# DANB RHS content inventory

Updated 2026-09-11 after public-source research. This replaces the earlier repository-only search that found no clinical material. Legal online access plus precise reference metadata is sufficient; a full document need not be committed.

## 1. Source inventory

See [source_register.md](source_register.md) for each title, institution, date/version, exact URL, section, access date, currency check and access limitation. Read material includes the official 2025 DANB outline, ADA 2024/2026 guidance summaries, FDA imaging guidance and CDC detailed dental infection-control pages. Supplementary ACR/RSNA patient-education pages support limited positioning/preparation facts. Full JADA articles and textbooks were not accessible/read and are not represented as verified sources.

## 2. Sourcing gate

This is an **authoring-source gate**, not human approval of a question.

| Domain | Gate for this batch | Limits |
| --- | --- | --- |
| `purpose_technique` | Passed for the specific sourced objectives in the reviewer packet | No anatomy questions; no detailed intraoral projection geometry or angulation-error questions. Selection questions cite ADA’s public summary, not unread full tables. |
| `radiation_protection` | Passed for the specific sourced objectives | No numerical dose limits, state-law claims, or detailed tube-production calculations. Shielding item explicitly scopes the ADA recommendation. |
| `infection_control` | Passed for the specific sourced objectives | No universal sensor reprocessing protocol or disinfectant contact time; device/product IFUs remain necessary. |

The outline establishes scope only. Clinical and technical keys have separate references. Conflicts, particularly legacy shielding wording, and superseded 2012 recommendations are addressed in the source register.

## 3. Production inventory (unchanged)

`rhs-dev-001` and `rhs-dev-002` remain draft in the production content file. There are **zero approved production questions**. No production source metadata, threshold, app setting or readiness calculation was changed. The workbench candidates are not bundled.

## 4. First editorial batch

Prepared: **26 draft candidates**, with exact inventory and reviewer content in [first_batch_review.md](first_batch_review.md).

| Domain | Editorial target | Drafts | Gap |
| --- | ---: | ---: | ---: |
| Purpose and Technique | 14 | 10 | 4 |
| Radiation Characteristics and Protection | 8 | 8 | 0 |
| Infection Prevention and Control | 8 | 8 | 0 |
| Total | 30 | 26 | 4 |

These are editorial counts, not exam weights or a mock-exam blueprint. The configured 50/25/25 weights remain unchanged. Draft difficulty labels are provisional author judgments on the existing 1–5 scale, not psychometric calibration. No review decisions are entered.

## 5. Missing material and safe source storage

The four unfilled slots need an actually accessed technical reference covering anatomical landmarks, paralleling geometry, horizontal overlap and vertical/receptor-placement errors. The source register identifies two DANB-listed editions suitable to investigate, without inventing chapter/page references. Full 2026 selection and 2024 safety papers would strengthen expert review of recommendation-specific questions. Do not fill gaps from memory or repeat the same learning objective simply to reach 30.

Keep licensed textbooks, paid materials, restricted PDFs and scans in authorized private storage (optionally the ignored `content_workbench/private_sources/` directory), never commit them merely to support this review. Even public access does not establish redistribution permission. This batch stores links, metadata and original wording only. The qualified human reviewer must open the cited sections, apply the repository checklist, and personally record the real identity/date/decision and matching fingerprint. A structural validator pass is not factual approval.
