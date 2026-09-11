# First DANB RHS draft batch — human review packet

Prepared 2026-09-11. **26 original English drafts; no human decisions or approvals.** This is an editorial batch, not an exam simulation or complete curriculum. Questions are reproduced from `candidate_questions.json`; that JSON is authoritative. No exam or textbook questions were consulted/copied. Source research supports authoring, not expert sign-off.

## Inventory

| Domain | Target | Drafts | Missing |
| --- | ---: | ---: | ---: |
| `purpose_technique` | 14 | 10 | 4 |
| `radiation_protection` | 8 | 8 | 0 |
| `infection_control` | 8 | 8 | 0 |

| Domain / topic | Drafts | Difficulty 1 | Difficulty 2 | Difficulty 3–5 |
| --- | ---: | ---: | ---: | ---: |
| `infection_control` / `equipment_precautions` | 6 | 0 | 6 | 0 |
| `infection_control` / `patient_operator_precautions` | 2 | 1 | 1 | 0 |
| `purpose_technique` / `acquisition_technique` | 2 | 0 | 2 | 0 |
| `purpose_technique` / `error_correction` | 1 | 0 | 1 | 0 |
| `purpose_technique` / `image_purpose` | 4 | 1 | 3 | 0 |
| `purpose_technique` / `image_quality` | 2 | 0 | 2 | 0 |
| `purpose_technique` / `patient_management` | 1 | 0 | 1 | 0 |
| `radiation_protection` / `patient_operator_protection` | 5 | 0 | 5 | 0 |
| `radiation_protection` / `radiation_biology` | 2 | 2 | 0 | 0 |
| `radiation_protection` / `radiation_physics` | 1 | 1 | 0 | 0 |

**Difficulty totals:** 1 = 5; 2 = 21; 3 = 0; 4 = 0; 5 = 0. These are provisional author judgments using the existing scale. This limited batch does not establish calibrated difficulty or exam readiness.

## Source and scope limits

Read [source_register.md](source_register.md) and [content_inventory.md](content_inventory.md) first. Each question below has the exact source URL, date/version, access date and locator. No full source document is redistributed.

- Four Purpose and Technique slots remain unfilled. Obtain authorized technical material on anatomical landmarks, paralleling geometry, horizontal overlap and vertical/receptor-placement errors; do not substitute near-duplicate general safety questions. Candidate textbooks and access failures are documented in the register.
- The 2026 endodontic and periodontal items cite the readable **ADA publisher summary**. The full JADA paper returned HTTP 403; an expert should consult the full recommendation and exceptions before deciding.
- The shielding item asks specifically about **ADA recommendations**, not universal law or operator shielding. Older FDA/RadiologyInfo wording conflicts with current ADA dental advice. Verify that distinction before approval.
- A heat-tolerant holder is not an electronic sensor. No blanket sensor sterilization/disinfection procedure or universal product contact time is supplied.
- No anatomy-image questions or licensed images are included. All production content remains unchanged and has zero approved questions.

## Reviewer instructions

1. Open the cited section yourself and apply [the full review checklist](../../docs/DANB_RHS_QUESTION_REVIEW_CHECKLIST.md) to each exact revision. Check every distractor as well as the key, explanation, topic and difficulty.
2. Run `dart run tool/validate_candidate_questions.dart --report` from the repository root. It must still report structural validity; this is not factual review.
3. Compare the JSON revision/text with this packet. The fingerprints below were computed by the existing exported `computeContentFingerprint(Question)` function, using decoded `Question` objects and algorithm `sha256-canonical-json-v1`. **The current CLI report prints statuses but does not print fingerprints**, despite the workflow wording. No validator code was changed. If material content changes, increment its version and regenerate the packet/fingerprints using that same function before review; do not reuse the old hash.
4. Only the qualified human reviewer records `questionId`, `contentFingerprint`, `contentFingerprintAlgorithm`, `decision` (`approve`, `revise` or `reject`), their real `reviewerIdentity`, `reviewDate` and notes in `reviewer_decisions.json`. Identity and decision are intentionally not prefilled. Notes must describe required revisions/rejection reasons.
5. Rerun the validator after decisions. Follow [the approval workflow](../../docs/DANB_RHS_CONTENT_APPROVAL_WORKFLOW.md) for any later manual promotion. Merging this draft-content PR is not clinical approval and does not promote anything into the app.

## Questions

### rhs-cand-purpose_technique-001

**Topic:** `purpose_technique` / `image_purpose`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `complement-clinical-examination`

A patient asks why the dentist might request images after examining the mouth. What additional information can radiographs provide?

- **A.** Conditions hidden from direct clinical inspection
- **B.** A replacement for the medical history
- **C.** A definitive diagnosis of every oral lesion
- **D.** Proof that future dental disease cannot develop

**Correct answer:** A — Conditions hidden from direct clinical inspection

**Rationale:** Radiographs can reveal otherwise unseen disease. They supplement history and examination; they neither diagnose every lesion nor predict freedom from future disease.

**References:**

- [X-rays](https://www.mouthhealthy.org/all-topics-a-z/x-rays/). American Dental Association, MouthHealthy; undated page; refers to 2024 recommendations; accessed 2026-09-11. Section: Opening paragraph; When you need X-rays.

**Source version:** ADA-PATIENT; undated page; refers to 2024 recommendations; accessed 2026-09-11

**Expert focus:** Check that the limited diagnostic claim is appropriate and does not imply radiographs replace examination.

**Fingerprint** (`sha256-canonical-json-v1`): `97988a818002b54ea95107c3860e20e7bb4b659f6d7e3e8d29a657e9f674d5de`

### rhs-cand-purpose_technique-002

**Topic:** `purpose_technique` / `image_purpose`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `initial-endodontic-imaging`

According to the ADA’s 2026 summary, which imaging approach is primary for an initial endodontic evaluation?

- **A.** Routine CBCT before clinical examination
- **B.** Intraoral two-dimensional radiographs
- **C.** Panoramic imaging as the only assessment
- **D.** CBCT instead of all intraoral imaging

**Correct answer:** B — Intraoral two-dimensional radiographs

**Rationale:** Intraoral 2D imaging is the primary initial modality. CBCT may follow clinical and 2D assessment when indicated; neither automatic CBCT nor panoramic imaging alone is the stated primary approach.

**References:**

- [New ADA recommendations confirm dental imaging most effectively used in moderation](https://adanews.ada.org/ada-news/2026/january/new-ada-recommendations-confirm-dental-imaging-most-effectively-used-in-moderation/). American Dental Association, ADA News; January 2026 article; reports recommendations published January 5, 2026; accessed 2026-09-11. Section: Specialty recommendations: endodontic evaluation bullet.

**Source version:** ADA-NEWS-2026; January 2026 article; reports recommendations published January 5, 2026; accessed 2026-09-11

**Expert focus:** Open the full 2026 recommendations if available; confirm exceptions and that this tests the initial modality, not a complete prescribing algorithm.

**Fingerprint** (`sha256-canonical-json-v1`): `057278a9d786afac1641e2770508079b3dbbe97868fb17745836c8da2e4ffa79`

### rhs-cand-purpose_technique-003

**Topic:** `purpose_technique` / `image_purpose`  
**Difficulty:** 1/5 · **Revision:** 2 · **Status:** draft / awaiting human review  
**Objective:** `cbct-dimensional-data`

What distinguishes the image data produced by dental CBCT from a conventional two-dimensional dental radiograph?

- **A.** A single flat projection
- **B.** A set of external facial photographs
- **C.** A three-dimensional reconstruction
- **D.** A continuous two-dimensional display

**Correct answer:** C — A three-dimensional reconstruction

**Rationale:** CBCT reconstructs a volume from X-ray projections. A single flat projection, external photographs, or a continuous 2D display does not describe that volumetric result.

**References:**

- [Dental Cone-beam Computed Tomography](https://www.fda.gov/radiation-emitting-products/medical-x-ray-imaging/dental-cone-beam-computed-tomography). U.S. Food and Drug Administration; undated web page; accessed 2026-09-11. Section: Description.

**Source version:** FDA-CBCT; undated web page; accessed 2026-09-11

**Expert focus:** Confirm distractor plausibility and basic difficulty; do not interpret 3D capability as justification for routine CBCT.

**Fingerprint** (`sha256-canonical-json-v1`): `b73fb74b57f3be99a56145e5f353bdb0a7cc3dc8010064bff43af17beb2deb43`

### rhs-cand-purpose_technique-004

**Topic:** `purpose_technique` / `error_correction`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `remove-external-metal`

Before a panoramic exposure, earrings lie within the imaging region. What should the team do to reduce interference?

- **A.** Increase exposure time
- **B.** Correct all interference afterward
- **C.** Leave them in place if the patient is still
- **D.** Ask the patient to remove them

**Correct answer:** D — Ask the patient to remove them

**Rationale:** Metal in the imaging region can interfere with the image. Removal addresses this risk; extra exposure, stillness alone, or assumed software correction does not remove the object.

**References:**

- [Panoramic Dental X-ray](https://www.radiologyinfo.org/en/info/panoramic-xray). RadiologyInfo.org, American College of Radiology / Radiological Society of North America; last reviewed 2024-09-09; accessed 2026-09-11. Section: How should I prepare?.

**Source version:** RI-PAN; last reviewed 2024-09-09; accessed 2026-09-11

**Expert focus:** Confirm preparation wording and applicability; no jewelry-specific artifact pattern is claimed. Exclude the source’s older apron advice.

**Fingerprint** (`sha256-canonical-json-v1`): `babcd6d8caaddd3504de3d9e6b3b02e434bf22fa08fc1c557ecbd06a13045ee2`

### rhs-cand-purpose_technique-005

**Topic:** `purpose_technique` / `acquisition_technique`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `panoramic-positioning-purpose`

What is the purpose of correct bite-block and head positioning during panoramic acquisition?

- **A.** Align the teeth and head for a clear image
- **B.** Replace the need to keep still
- **C.** Determine whether imaging is clinically indicated
- **D.** Set the exposure automatically for every patient

**Correct answer:** A — Align the teeth and head for a clear image

**Rationale:** Positioning supports image clarity and alignment. It does not replace stillness, establish clinical need, or determine a universal exposure setting.

**References:**

- [Panoramic Dental X-ray](https://www.radiologyinfo.org/en/info/panoramic-xray). RadiologyInfo.org, American College of Radiology / Radiological Society of North America; last reviewed 2024-09-09; accessed 2026-09-11. Section: How is the procedure performed?.

**Source version:** RI-PAN; last reviewed 2024-09-09; accessed 2026-09-11

**Expert focus:** Confirm that this general technique statement does not imply every unit has identical positioning hardware or IFUs.

**Fingerprint** (`sha256-canonical-json-v1`): `b0705092e41efbe28df76d6acbadbf4b1e70f712bfb85fd065b01c5051747887`

### rhs-cand-purpose_technique-006

**Topic:** `purpose_technique` / `acquisition_technique`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `cbct-stillness`

During a dental CBCT acquisition, what instruction should the patient follow as the source and detector move?

- **A.** Turn the head to follow the detector
- **B.** Remain still in the position established by the team
- **C.** Reposition the chin at each projection
- **D.** Open and close the mouth throughout the scan

**Correct answer:** B — Remain still in the position established by the team

**Rationale:** The team positions the patient before acquisition; the patient then remains still. Following the detector, moving the chin, or repeatedly moving the jaw conflicts with that instruction.

**References:**

- [Dental Cone Beam CT](https://www.radiologyinfo.org/en/info/dentalconect). RadiologyInfo.org, American College of Radiology / Radiological Society of North America; last reviewed 2026-06-01; accessed 2026-09-11. Section: How is the procedure performed?.

**Source version:** RI-CBCT; last reviewed 2026-06-01; accessed 2026-09-11

**Expert focus:** Confirm this is a general acquisition instruction; no fixed scan duration or rotation angle is implied.

**Fingerprint** (`sha256-canonical-json-v1`): `0188aa822d6fe6fe2301ff5aaef3a5dbb09e5341f14cd2d76a4f510379d99ec6`

### rhs-cand-purpose_technique-007

**Topic:** `purpose_technique` / `image_quality`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `digital-exposure-creep`

An operator repeatedly raises digital exposure to make image noise less noticeable. Which concern does this illustrate?

- **A.** A reduction in patient exposure
- **B.** Removal of the need for quality control
- **C.** Exposure creep
- **D.** A substitute for patient positioning

**Correct answer:** C — Exposure creep

**Rationale:** Exposure creep describes dose increases made to suppress visible noise. It increases rather than reduces exposure and does not replace quality control or positioning.

**References:**

- [X-Rays/Radiographs](https://www.ada.org/resources/ada-library/oral-health-topics/x-rays-radiographs). American Dental Association; updated 2026-03-26; accessed 2026-09-11. Section: Dental Radiographic Technology: paragraph on image noise.

**Source version:** ADA-TOPIC; updated 2026-03-26; accessed 2026-09-11

**Expert focus:** Check the term and ensure the item does not imply all exposure adjustment is inappropriate.

**Fingerprint** (`sha256-canonical-json-v1`): `25affcef1be63aa36e229e60a8bf108e444bd6578c05f4ca4e8b01cee0bfd70f`

### rhs-cand-purpose_technique-008

**Topic:** `purpose_technique` / `image_quality`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `diagnostic-adequacy`

When selecting exposure for a justified dental image, which quality goal fits optimization?

- **A.** The smoothest image regardless of dose
- **B.** The lowest setting even if anatomy is unreadable
- **C.** The same setting for every patient
- **D.** Diagnostic adequacy at the lowest reasonably needed dose

**Correct answer:** D — Diagnostic adequacy at the lowest reasonably needed dose

**Rationale:** Optimization balances usable diagnostic information with dose reduction. Cosmetic smoothness, unreadable minimum-dose images, and universal settings fail that balance.

**References:**

- [Medical X-ray Imaging](https://www.fda.gov/radiation-emitting-products/medical-imaging/medical-x-ray-imaging). U.S. Food and Drug Administration; undated web page; accessed 2026-09-11. Section: Principles of radiation protection: justification and optimization, item 2.

**Source version:** FDA-XRAY; undated web page; accessed 2026-09-11

**Expert focus:** Review domain placement: primary objective is acceptable image quality; the dose principle overlaps protection but is not repeated as a separate ALARA item.

**Fingerprint** (`sha256-canonical-json-v1`): `673ba4057da250e5faf579cf2dd61d177d989b4799ee25540f857a3c35e120ec`

### rhs-cand-purpose_technique-009

**Topic:** `purpose_technique` / `patient_management`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `patient-imaging-discussion`

A patient is worried about a recommended CBCT examination. What is the most appropriate response before proceeding?

- **A.** Invite discussion with the dentist about its purpose, benefits, risks and alternatives
- **B.** Promise that the examination has no radiation risk
- **C.** State that owning a scanner makes the examination necessary
- **D.** Explain that questions should wait until after exposure

**Correct answer:** A — Invite discussion with the dentist about its purpose, benefits, risks and alternatives

**Rationale:** FDA encourages informed discussion before imaging. Zero-risk assurances are inaccurate; equipment availability is not justification, and postponing questions prevents that discussion.

**References:**

- [Dental Cone-beam Computed Tomography](https://www.fda.gov/radiation-emitting-products/medical-x-ray-imaging/dental-cone-beam-computed-tomography). U.S. Food and Drug Administration; undated web page; accessed 2026-09-11. Section: Information for Patients and Parents.

**Source version:** FDA-CBCT; undated web page; accessed 2026-09-11

**Expert focus:** Confirm assistant role is supportive communication, not independent prescribing or a jurisdiction-specific consent rule.

**Fingerprint** (`sha256-canonical-json-v1`): `8a6cfdb6267d8c2a933587460f0b068c99736694da338d51a63e591305b3df3d`

### rhs-cand-purpose_technique-010

**Topic:** `purpose_technique` / `image_purpose`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `periodontal-baseline-imaging`

For periodontal evaluation, which approach does the ADA’s 2026 summary identify as the established standard?

- **A.** Routine CBCT without clinical examination
- **B.** A 2D full-mouth series together with clinical examination
- **C.** A panoramic image without clinical findings
- **D.** Imaging only after all treatment is finished

**Correct answer:** B — A 2D full-mouth series together with clinical examination

**Rationale:** The summary supports a full-mouth 2D series plus examination. Routine CBCT, an isolated panoramic image, or deferring all imaging until after treatment does not describe that approach.

**References:**

- [New ADA recommendations confirm dental imaging most effectively used in moderation](https://adanews.ada.org/ada-news/2026/january/new-ada-recommendations-confirm-dental-imaging-most-effectively-used-in-moderation/). American Dental Association, ADA News; January 2026 article; reports recommendations published January 5, 2026; accessed 2026-09-11. Section: Periodontal disease management paragraph.

**Source version:** ADA-NEWS-2026; January 2026 article; reports recommendations published January 5, 2026; accessed 2026-09-11

**Expert focus:** Check full-text context and patient selection. This describes an evaluation approach, not automatic full-mouth imaging at every visit.

**Fingerprint** (`sha256-canonical-json-v1`): `2dcf0e160951a45c1d8381e5d8e0fb89a4ceeeeacdf6d4fe0c043ce36ef571b4`

### rhs-cand-radiation_protection-001

**Topic:** `radiation_protection` / `radiation_physics`  
**Difficulty:** 1/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `beam-interaction`

As an X-ray beam passes through a patient, what happens to its photons?

- **A.** All are stored in the tissues
- **B.** All reach the detector unchanged
- **C.** Some are absorbed or scattered, while others are transmitted
- **D.** All are converted into visible light before reaching the detector

**Correct answer:** C — Some are absorbed or scattered, while others are transmitted

**Rationale:** The detector receives the transmitted pattern after absorption and scattering within the patient. Storage, unchanged transmission of every photon, and complete conversion to visible light are not this process.

**References:**

- [Radiography](https://www.fda.gov/radiation-emitting-products/medical-x-ray-imaging/radiography). U.S. Food and Drug Administration; undated web page; accessed 2026-09-11. Section: Description: paragraph beginning During a radiographic procedure.

**Source version:** FDA-RAD; undated web page; accessed 2026-09-11

**Expert focus:** Review basic photon wording and avoid importing the source’s outdated general shielding advice.

**Fingerprint** (`sha256-canonical-json-v1`): `67d4a0db088a7f3f6a5e0974aea1d3cb4761e119e50578f78ab80cbc2610b6df`

### rhs-cand-radiation_protection-002

**Topic:** `radiation_protection` / `radiation_biology`  
**Difficulty:** 1/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `ionization-dna`

Why does ionizing radiation used in dental imaging require protection measures?

- **A.** It makes every exposed patient develop cancer
- **B.** Its effects are limited to warming the skin
- **C.** It cannot interact with living cells
- **D.** It can damage DNA

**Correct answer:** D — It can damage DNA

**Rationale:** Ionizing radiation can damage DNA and increase cancer risk. Risk is not a certainty of cancer; neither heat alone nor an inability to interact with cells describes the concern.

**References:**

- [Medical X-ray Imaging](https://www.fda.gov/radiation-emitting-products/medical-imaging/medical-x-ray-imaging). U.S. Food and Drug Administration; undated web page; accessed 2026-09-11. Section: Description; Risks.

**Source version:** FDA-XRAY; undated web page; accessed 2026-09-11

**Expert focus:** Check that the explanation communicates risk without claiming a predictable outcome for an individual exposure.

**Fingerprint** (`sha256-canonical-json-v1`): `c1a673820219f0b1d2a1173dbaf5935deb3f509495fe13cd4159aa856941c360`

### rhs-cand-radiation_protection-003

**Topic:** `radiation_protection` / `radiation_biology`  
**Difficulty:** 1/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `pediatric-radiosensitivity`

Why is particular attention to radiation protection appropriate for children?

- **A.** They are more radiosensitive and have more remaining years for effects to develop
- **B.** They receive no natural background radiation
- **C.** They cannot benefit from diagnostically necessary images
- **D.** They have the same risk per unit dose as every adult

**Correct answer:** A — They are more radiosensitive and have more remaining years for effects to develop

**Rationale:** FDA identifies greater radiosensitivity and a longer remaining lifetime. Background exposure is not absent, necessary imaging can benefit children, and equal risk per unit dose is not the stated basis.

**References:**

- [Pediatric X-ray Imaging](https://www.fda.gov/radiation-emitting-products/medical-imaging/pediatric-x-ray-imaging). U.S. Food and Drug Administration; undated web page; accessed 2026-09-11. Section: X-ray Imaging for Pediatrics: risk bullets.

**Source version:** FDA-PED; undated web page; accessed 2026-09-11

**Expert focus:** Confirm risk wording; no exact individual cancer probability or age cutoff is asserted.

**Fingerprint** (`sha256-canonical-json-v1`): `c692160bbc23aec937c91a73becdcfa72b5e605552f9a8ff8de9d2a7aa398e27`

### rhs-cand-radiation_protection-004

**Topic:** `radiation_protection` / `patient_operator_protection`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `pediatric-exposure-selection`

A small child needs a justified X-ray examination. How should exposure settings be selected?

- **A.** Use adult settings because the equipment is the same
- **B.** Use an appropriate pediatric protocol considering size and the clinical task
- **C.** Use age alone and disregard body size
- **D.** Use the maximum setting to avoid any chance of noise

**Correct answer:** B — Use an appropriate pediatric protocol considering size and the clinical task

**Rationale:** FDA emphasizes patient size, the clinical task and pediatric protocols. Adult defaults, age alone, or maximum exposure can give inappropriate dose; adequate image quality remains necessary.

**References:**

- [Pediatric X-ray Imaging](https://www.fda.gov/radiation-emitting-products/medical-imaging/pediatric-x-ray-imaging). U.S. Food and Drug Administration; undated web page; accessed 2026-09-11. Section: X-ray Imaging for Pediatrics; Information for Health Care Professionals: pediatric protocols.

**Source version:** FDA-PED; undated web page; accessed 2026-09-11

**Expert focus:** Confirm clinical-role wording and that no unsourced numeric technique settings are implied.

**Fingerprint** (`sha256-canonical-json-v1`): `d7a4798caa37005724d1a2d171725cf66a660fafe985cf4bc73158591cb14572`

### rhs-cand-radiation_protection-005

**Topic:** `radiation_protection` / `patient_operator_protection`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `cbct-justification`

The dentist determines that a lower-exposure examination can supply all information needed for a clinical question. What supports radiation protection?

- **A.** Add CBCT solely because it produces 3D images
- **B.** Acquire both examinations routinely
- **C.** Use the adequate lower-exposure option
- **D.** Use CBCT whenever the scanner is available

**Correct answer:** C — Use the adequate lower-exposure option

**Rationale:** CBCT should be justified by information not adequately supplied by lower-exposure options. Routine duplication, 3D capability alone, and availability do not establish that need.

**References:**

- [Dental Cone-beam Computed Tomography](https://www.fda.gov/radiation-emitting-products/medical-x-ray-imaging/dental-cone-beam-computed-tomography). U.S. Food and Drug Administration; undated web page; accessed 2026-09-11. Section: Information for Dental Professionals: necessary information and justification.

**Source version:** FDA-CBCT; undated web page; accessed 2026-09-11

**Expert focus:** Check against current ADA recommendations and keep the clinical determination with the dentist.

**Fingerprint** (`sha256-canonical-json-v1`): `a0842fbf0604ad4bf3fb9ce021fd948242cc0c8d60d29d814d3ac7700fd4c9f9`

### rhs-cand-radiation_protection-006

**Topic:** `radiation_protection` / `patient_operator_protection`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `beam-size-restriction`

Which change directly restricts the X-ray beam to the region that needs imaging?

- **A.** Increase display brightness
- **B.** Lengthen the exposure
- **C.** Enlarge the irradiated field
- **D.** Use rectangular collimation

**Correct answer:** D — Use rectangular collimation

**Rationale:** Rectangular collimation limits the beam’s extent. Display brightness changes viewing, while longer exposure or a larger field does not restrict the irradiated region.

**References:**

- [ADA Releases Updated Recommendations to Enhance Radiography Safety in Dentistry](https://www.ada.org/about/press-releases/ada-releases-updated-recommendations-to-enhance-radiography-safety-in-dentistry). American Dental Association; published 2024-02-01; accessed 2026-09-11. Section: Dose-reduction recommendation bullets: rectangular collimation.

**Source version:** ADA-SAFETY-2024; published 2024-02-01; accessed 2026-09-11

**Expert focus:** Confirm scope is dental beam limitation; no unsourced numerical dose-reduction percentage is claimed.

**Fingerprint** (`sha256-canonical-json-v1`): `9cb7fe4ebcd805b2bffee99c69f506a63ba92f3a977bf831732fed3679cb5ea5`

### rhs-cand-radiation_protection-007

**Topic:** `radiation_protection` / `patient_operator_protection`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `ada-patient-shielding-recommendation`

What do the ADA’s 2024 recommendations advise about routine patient lead aprons and thyroid collars for dental imaging?

- **A.** Discontinue routine use while following applicable regulations
- **B.** Require them for every patient regardless of regulations
- **C.** Use them instead of limiting beam size
- **D.** Use them to justify otherwise unnecessary imaging

**Correct answer:** A — Discontinue routine use while following applicable regulations

**Rationale:** ADA advises against routine patient shielding and notes possible beam obstruction. Applicable rules still matter. Shielding neither replaces beam limitation nor justifies imaging; universal mandatory use is not the ADA recommendation.

**References:**

- [ADA Releases Updated Recommendations to Enhance Radiography Safety in Dentistry](https://www.ada.org/about/press-releases/ada-releases-updated-recommendations-to-enhance-radiography-safety-in-dentistry). American Dental Association; published 2024-02-01; accessed 2026-09-11. Section: Patient shielding paragraphs; final recommendation on applicable regulations.

**Source version:** ADA-SAFETY-2024; published 2024-02-01; accessed 2026-09-11

**Expert focus:** Priority review: verify 2024/2026 currency, distinction from operator shielding and local law, and suitability for an exam whose outline predates the 2026 update.

**Fingerprint** (`sha256-canonical-json-v1`): `a43857a1bf8c46d3424faa6016330599e7f91ebed98297a28b6969ad3eefa664`

### rhs-cand-radiation_protection-008

**Topic:** `radiation_protection` / `patient_operator_protection`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `reuse-prior-images`

A new patient reports recent images from another dental office. What step may avoid unnecessary repeat exposure?

- **A.** Repeat the entire series before requesting records
- **B.** Request the existing images for the dentist to assess
- **C.** Assume outside images are unusable
- **D.** Treat a change of office as an automatic indication for new images

**Correct answer:** B — Request the existing images for the dentist to assess

**Rationale:** Existing images may meet the dentist’s information needs. Their adequacy should be assessed; relocation, assumed unusability, or repeating before review does not establish a need for new exposure.

**References:**

- [X-rays](https://www.mouthhealthy.org/all-topics-a-z/x-rays/). American Dental Association, MouthHealthy; undated page; refers to 2024 recommendations; accessed 2026-09-11. Section: When you need X-rays: new-patient paragraph.

**Source version:** ADA-PATIENT; undated page; refers to 2024 recommendations; accessed 2026-09-11

**Expert focus:** Confirm this does not promise all prior images are adequate or prescribe a fixed retention/transfer rule.

**Fingerprint** (`sha256-canonical-json-v1`): `6c113bad54ef417e79c7cf2396e1ab59bf2bc0fce9f8d3091a5601f167258c1e`

### rhs-cand-infection_control-001

**Topic:** `infection_control` / `equipment_precautions`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `contaminated-barrier-surface`

After removing a used barrier from an X-ray control surface, the assistant sees contamination underneath. What is required before the next patient?

- **A.** Place a new barrier over the contamination
- **B.** Wipe with a dry towel only
- **C.** Clean and disinfect the surface, then replace the barrier
- **D.** Leave the barrier off for the next patient

**Correct answer:** C — Clean and disinfect the surface, then replace the barrier

**Rationale:** A contaminated underlying surface needs cleaning and disinfection before a fresh barrier. Covering contamination, dry wiping alone, or omitting the barrier does not complete decontamination.

**References:**

- [Best Practices for Environmental Infection Prevention and Control](https://www.cdc.gov/dental-infection-control/hcp/dental-ipc-faqs/cleaning-disinfecting-environmental-surface.html). Centers for Disease Control and Prevention; 2024-05-15; accessed 2026-09-11. Section: Clinical contact surfaces: barrier removal and surface inspection.

**Source version:** CDC-ENV; 2024-05-15; accessed 2026-09-11

**Expert focus:** Check task sequence and product compatibility; do not infer a universal disinfectant contact time.

**Fingerprint** (`sha256-canonical-json-v1`): `c84c34e81f128d92b63e9cdf31a49fb6492fcaab84262b1078bfedb64c48575f`

### rhs-cand-infection_control-002

**Topic:** `infection_control` / `equipment_precautions`  
**Difficulty:** 2/5 · **Revision:** 2 · **Status:** draft / awaiting human review  
**Objective:** `blood-contaminated-surface`

An unbarriered clinical contact surface has visible blood. After cleaning, which disinfectant category does CDC recommend?

- **A.** An FDA-cleared high-level instrument disinfectant
- **B.** An EPA-registered low-level hospital disinfectant
- **C.** A detergent without a hospital-disinfectant claim
- **D.** An EPA-registered tuberculocidal hospital disinfectant

**Correct answer:** D — An EPA-registered tuberculocidal hospital disinfectant

**Rationale:** Visible blood calls for the specified intermediate-level product, used as labeled. Low-level disinfection or detergent alone is insufficient; high-level instrument chemicals should not be used on environmental surfaces.

**References:**

- [Best Practices for Environmental Infection Prevention and Control](https://www.cdc.gov/dental-infection-control/hcp/dental-ipc-faqs/cleaning-disinfecting-environmental-surface.html). Centers for Disease Control and Prevention; 2024-05-15; accessed 2026-09-11. Section: Clinical contact surfaces; Choosing the right product.

**Source version:** CDC-ENV; 2024-05-15; accessed 2026-09-11

**Expert focus:** Confirm the product category: tuberculocidal hospital disinfectant denotes intermediate-level disinfection; use according to labeling.

**Fingerprint** (`sha256-canonical-json-v1`): `37627f2c219f05d4373030c9a8c141d3cf171949e5ab874490855918b4fb0fc9`

### rhs-cand-infection_control-003

**Topic:** `infection_control` / `equipment_precautions`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `heat-tolerant-holder`

A reusable receptor holder contacts oral mucosa and its validated instructions permit heat sterilization. What processing is appropriate between patients?

- **A.** Clean and heat-sterilize it according to its instructions
- **B.** Rinse it and fit a new barrier only
- **C.** Use surface disinfectant instead of sterilization
- **D.** Store it until visible contamination dries

**Correct answer:** A — Clean and heat-sterilize it according to its instructions

**Rationale:** This heat-tolerant semicritical item requires heat sterilization after cleaning. Rinsing/barriers, surface disinfection alone, and drying are not substitutes. This does not prescribe processing for electronic sensors.

**References:**

- [Best Practices for Sterilization in Dental Settings](https://www.cdc.gov/dental-infection-control/hcp/dental-ipc-faqs/dental-sterilization.html). Centers for Disease Control and Prevention; 2024-05-15; accessed 2026-09-11. Section: Instrument classification; Recommendations; Cleaning.

**Source version:** CDC-STER; 2024-05-15; accessed 2026-09-11

**Expert focus:** Priority review: confirm semicritical classification and explicit heat-tolerant IFU condition; avoid extending this rule to all sensors.

**Fingerprint** (`sha256-canonical-json-v1`): `6e6dc1e8512334733a3dfe642c772cba744dc4fec50b81cfe3ecc8bf537a0432`

### rhs-cand-infection_control-004

**Topic:** `infection_control` / `equipment_precautions`  
**Difficulty:** 2/5 · **Revision:** 2 · **Status:** draft / awaiting human review  
**Objective:** `damaged-sterile-package`

A packaged, sterilized heat-tolerant receptor holder is found in a torn pouch before use. What should the assistant do?

- **A.** Use it if the original date is recent
- **B.** Reprocess it with cleaning, packaging and heat sterilization
- **C.** Tape the tear and use it
- **D.** Move it to a new pouch without reprocessing

**Correct answer:** B — Reprocess it with cleaning, packaging and heat sterilization

**Rationale:** A torn package compromises maintained sterility. CDC calls for complete reprocessing; a recent date, tape, or a replacement pouch alone cannot restore it.

**References:**

- [Best Practices for Sterilization in Dental Settings](https://www.cdc.gov/dental-infection-control/hcp/dental-ipc-faqs/dental-sterilization.html). Centers for Disease Control and Prevention; 2024-05-15; accessed 2026-09-11. Section: Storage: compromised packaging.

**Source version:** CDC-STER; 2024-05-15; accessed 2026-09-11

**Expert focus:** Check that the scenario remains a heat-tolerant holder and does not imply every damaged device itself is reusable.

**Fingerprint** (`sha256-canonical-json-v1`): `b3df5e99a10f10075a1e71b0a229419bfa3c5d5007bc68edea4c2da6deb1850b`

### rhs-cand-infection_control-005

**Topic:** `infection_control` / `equipment_precautions`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `single-use-accessory`

A receptor-positioning accessory is labeled single-use. What should happen after its use for one patient’s procedure?

- **A.** Clean it for the next patient
- **B.** Keep it until it looks worn
- **C.** Dispose of it appropriately
- **D.** Sterilize it to convert it into a reusable item

**Correct answer:** C — Dispose of it appropriately

**Rationale:** Single-use devices are not intended for routine reprocessing and reuse by the dental office. Cleaning, keeping, or sterilizing the accessory does not change its intended use.

**References:**

- [Best Practices for Single-Use (Disposable) Devices](https://www.cdc.gov/dental-infection-control/hcp/dental-ipc-faqs/single-use-devices.html). Centers for Disease Control and Prevention; 2024-05-15; accessed 2026-09-11. Section: Key points; Recommendations.

**Source version:** CDC-SINGLE; 2024-05-15; accessed 2026-09-11

**Expert focus:** Confirm wording concerns office reuse, not a separately regulated reprocessing service; disposal must follow applicable waste rules.

**Fingerprint** (`sha256-canonical-json-v1`): `534274862a36429dc4621507409074e7f933b8b2c9448476143cedb18f3fbfc0`

### rhs-cand-infection_control-006

**Topic:** `infection_control` / `patient_operator_precautions`  
**Difficulty:** 1/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `glove-hand-hygiene-timing`

When does hand hygiene belong in the sequence for wearing examination gloves?

- **A.** Only at the start of the workday
- **B.** Only if a tear is visible
- **C.** Only after all patients have been seen
- **D.** Immediately before putting them on and after removing them

**Correct answer:** D — Immediately before putting them on and after removing them

**Rationale:** Gloves do not replace hand hygiene. Small defects and removal can contaminate hands, so waiting for visible damage or a workday boundary is inadequate.

**References:**

- [Best Practices for Personal Protective Equipment](https://www.cdc.gov/dental-infection-control/hcp/dental-ipc-faqs/personal-protective-equipment.html). Centers for Disease Control and Prevention; 2024-05-15; accessed 2026-09-11. Section: Frequently asked questions: Do gloves replace the need for handwashing?.

**Source version:** CDC-PPE; 2024-05-15; accessed 2026-09-11

**Expert focus:** Confirm timing and distinguish it from the next item’s separate choice of method for visibly soiled hands.

**Fingerprint** (`sha256-canonical-json-v1`): `c921aaf11d985fb1365843b535d158db3be35af89a5fe3e15edc1cdcfe3ee9c8`

### rhs-cand-infection_control-007

**Topic:** `infection_control` / `patient_operator_precautions`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `visibly-soiled-hands`

After glove removal, an assistant’s hands are visibly soiled. Which hand-hygiene method should be used?

- **A.** Wash with soap and water
- **B.** Apply alcohol hand rub without washing
- **C.** Cover the soil with clean gloves
- **D.** Wipe the hands on a dry towel

**Correct answer:** A — Wash with soap and water

**Rationale:** CDC specifies soap and water for visibly soiled hands. Alcohol rub alone, covering with gloves, and dry wiping do not meet that recommendation.

**References:**

- [Clinical Safety: Hand Hygiene for Healthcare Workers](https://www.cdc.gov/clean-hands/hcp/clinical-safety/index.html). Centers for Disease Control and Prevention; 2024-02-27; accessed 2026-09-11. Section: Know when to use alcohol-based hand sanitizer versus soap and water: When to wash with soap and water.

**Source version:** CDC-HANDS; 2024-02-27; accessed 2026-09-11

**Expert focus:** Confirm visible soil is explicit; do not imply alcohol hand rub is inappropriate for all routine hand hygiene.

**Fingerprint** (`sha256-canonical-json-v1`): `43e6d31fb5ffec0300532291bf8e442ea6e0adab9f8283e887011d2bc15ba692`

### rhs-cand-infection_control-008

**Topic:** `infection_control` / `equipment_precautions`  
**Difficulty:** 2/5 · **Revision:** 1 · **Status:** draft / awaiting human review  
**Objective:** `combined-sterilization-monitoring`

A chemical indicator changed color in a sterilized instrument package. How should that finding be used?

- **A.** As permission to stop biological monitoring
- **B.** Alongside mechanical and biological monitoring
- **C.** As a replacement for reviewing cycle parameters
- **D.** As proof that cleaning before sterilization was unnecessary

**Correct answer:** B — Alongside mechanical and biological monitoring

**Rationale:** Chemical indicators are one part of monitoring, not a substitute for mechanical or biological checks. A color change also does not remove the need for cleaning.

**References:**

- [Best Practices for Sterilization Monitoring in Dental Settings](https://www.cdc.gov/dental-infection-control/hcp/dental-ipc-faqs/sterilization-monitoring.html). Centers for Disease Control and Prevention; 2024-05-15; accessed 2026-09-11. Section: Why it matters; Chemical monitoring; Biological monitoring.

**Source version:** CDC-MON; 2024-05-15; accessed 2026-09-11

**Expert focus:** Confirm explanation avoids equating a color change with guaranteed sterility; review relevance to radiographic instrument processing.

**Fingerprint** (`sha256-canonical-json-v1`): `6237cd29ebd699116b6bdd1b6b0a420edc6db0f36c5ba67e2627be5da390ae4b`

