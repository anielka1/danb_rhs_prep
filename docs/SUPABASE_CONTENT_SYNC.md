# Published question-bank sync

Production `main()` wires `SyncedContentRepository` around the existing
`BundledContentRepository`. Screens and domain engines still receive the same
`ContentPackage` through `AppBootstrapService`; none query Supabase or SQLite.
The demo entrypoints and default unit/widget compositions have no remote source.
No login, anonymous sign-in, Auth storage, realtime subscription or account is
created. The requested `supabase_flutter` SDK is pinned to 2.17.2; `crypto` 3.0.7
is now a runtime dependency for transport checksums. Reviewer fingerprints and
approval rules are unchanged.

## Local configuration

Use Flutter 3.41.2 / Dart 3.11.0, matching this repository's tested toolchain.
Supabase Flutter 2.17.2 requires at least Flutter 3.35 and Dart 3.9. The root
package retains its existing Dart 3.3 language version (and formatter style);
that language setting does not remove the dependency's newer SDK requirement.

Provide your project's HTTPS base URL and **publishable** key at build time:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Alternatively copy `config/supabase.example.json` to a private file **outside the
repository**, replace both placeholders locally and run:

```bash
flutter run --dart-define-from-file=/absolute/private/path/supabase.local.json
```

Combine these with the existing RevenueCat configuration when testing Premium
features. Content synchronization does not grant Premium or change access rules.
A full process restart/rebuild is required after changing dart-defines; hot reload
is insufficient. Never use a secret key, service-role key or legacy JWT here.
Only modern `sb_publishable_…` keys are accepted. Missing/invalid configuration
turns off remote sync while local content continues to work. No key is logged.
No real credentials are included in the example or tests.

## Read-only server boundary

Project `danb-rhs-prep` was inspected on 2026-09-14. The only client query is:

- `public.question_bank_releases`;
- selected `exam_id` (the current production bootstrap supports `danb_rhs`);
- `published_at <=` the client's current UTC time, `retired_at IS NULL`;
- `release_version DESC`, limit one.

Server RLS additionally enforces publication time using the server clock and
non-retirement. The existing anon SELECT grant and RLS were verified. An actual
read under `SET LOCAL ROLE anon` returned **zero visible releases**. This is a
normal, supported state. No release, table, policy, grant or function was changed.
The `anon` and `authenticated` roles have no USAGE on `content_workbench`; the
adapter never queries that schema. Draft questions, answers, references and
reviewer decisions remain inaccessible to this client. The publisher must apply
the existing qualified-human review process before creating any release.

The SDK is instantiated only inside the data adapter, without Flutter's global
`Supabase.initialize` / Auth session persistence. Each request has a 12-second
transport timeout and automatic retries disabled; the client is disposed after
the request. No progress, settings, answers, bookmarks or user identifiers are
sent. Supabase necessarily receives normal request metadata such as IP address.

## Release schema 1 contract

| Field | Validation |
| --- | --- |
| `exam_id` | Exact selected exam ID, also equal to `payload.exam.id` |
| `schema_version` | Positive integer, supported value `1` only |
| `release_version` | Positive integer, strictly greater than all cached versions for this exam |
| `content_version` | Exact payload content version; must not reuse a cached release's version label |
| `question_count` | Positive integer, exact number of payload questions |
| `payload` | JSON object in the existing `ExamContentCodec` format; at most 20 MiB canonical UTF-8 |
| `content_sha256` | Lowercase 64-character hex SHA-256 of the canonical payload below |
| `published_at`, `retired_at` | Parseable timezone-qualified publication at or before now; no retirement |

The existing codec and `ContentValidator` run before installation. Every question
in a downloaded release must already be `approved`; a valid checksum does not
approve content. Schema errors, missing fields, malformed JSON, wrong exam/count,
unsupported schema, validator errors or a single draft reject the **whole** bank.
Warnings retain the existing validator meaning and are not silently promoted to
new approval rules.

### Exact checksum contract

The server currently stores a checksum but has no published examples, column
comment or publisher function defining its algorithm. This client therefore
makes the schema-1 transport contract explicit; **interoperability with a real
publisher still needs verification before the first release**. No claim is made
that PostgreSQL `payload::text` produces these bytes.

`canonicalPayloadJson` / `contentPayloadSha256` in
`lib/features/content/sync/content_release.dart` are the reference implementation:

1. Recursively sort JSON object keys with Dart string ordering (UTF-16 code units).
2. Preserve array order and string values, including Unicode; do not trim text,
   sort answers, normalize Unicode or change question/reviewer fields.
3. Accept finite numbers within ±9007199254740991. Integral numeric values
   serialize as integers (`1.0` becomes `1`, `-0.0` becomes `0`). Other numbers
   use Dart `jsonEncode` representation.
4. Encode using Dart `jsonEncode`, no added whitespace/BOM/newline, then UTF-8.
5. SHA-256 those bytes, lowercase hex. No prefix or salt.

Use the reference helper instead of another language's default JSON serializer:

```bash
dart run tool/content_release_checksum.dart /path/to/reviewed-payload.json
```

That read-only helper prints a transport checksum; it does **not** review,
approve, publish, upload, or edit the input. It is separate from the existing
`danb-rhs-question-approval:v1` reviewer fingerprint. Approval fingerprints are
neither generated nor replaced by synchronization.

Publishers must allocate increasing `release_version` values and unique
`content_version` labels. The app does not order opaque content-version strings.
An automatically fetched release matching the bundled version is ignored.
Server-side retirement prevents new downloads; it is not an offline revocation
mechanism for banks already downloaded.

## Local storage, activation and failure handling

1. Bootstrap reads bundled content and the local Drift release cache. It never
   awaits a network response. The bundled bank remains the fallback for first
   launch, disabled configuration, unreadable cache or no valid cached release.
2. Previously downloaded records are revalidated. The newest valid one becomes
   active only if no practice or mock session is in progress. If session state
   cannot be read, keep the already activated bank and defer activation.
3. The process retains one immutable content snapshot. One background sync per
   exam/process fetches and validates a candidate. Network/validation/write
   failures leave the existing snapshot untouched and show no technical error.
4. An SQLite transaction appends a newer validated release **without deleting
   or deactivating the old bank**. A separate transaction activates it on a later
   bootstrap. Both roll back fully on a write failure.
5. Restart with an active session keeps the prior activated bank (or the bundle
   for a legacy session that predates this cache), preserving its questions and
   saved answer permutation. Finish/abandon the session normally, then restart
   to activate a waiting update. No session is automatically completed.

The separate `question_banks.sqlite` database has schema version 1. The existing
progress database stays at schema **5**, the actual version on current main;
there is no progress migration, clearing, history rewrite or settings change.
Old bank versions are retained, so storage grows with releases; garbage
collection is intentionally not introduced here. Read failures can fall back to
an older validated bank without removing the damaged row.

## Manual offline checks

1. On a disposable simulator install, run without Supabase dart-defines and with
   networking disabled. Complete onboarding; Home/Settings/Progress must open.
   The current production bundle has zero approved questions: its honest empty
   practice state is expected, not a connectivity error.
2. Run with valid configuration against the current empty releases table. Home
   must open normally; restarting offline must behave identically. Do not publish
   drafts just to make practice available.
3. After a qualified human has published a legitimate release using the checksum
   contract, launch online, allow the background fetch, then fully restart. New
   content should appear without changing history or granting Premium.
4. Start a session using eligible content and valid existing access. Download a
   later approved version, then restart offline: resume must keep question IDs,
   answer order and answers. Finish the session; restart to use the newer bank.
5. With the cached bank installed, disable internet and fully restart again.
   Previously available content and progress must remain available. Do not
   uninstall, clear app data or use a demo entrypoint to test durable production
   cache behavior.

Positive-release and error paths are tested with isolated fake remote sources
and temporary Drift databases, without contacting Supabase. The empty real
project cannot demonstrate a positive published-content download. No real
release was created as part of this integration.
