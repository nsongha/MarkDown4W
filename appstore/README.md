# App Store release kit — MarkDown4W

Everything needed to ship MarkDown4W to the Mac App Store (free).

## What's already done (in code)
- ✅ `project.yml` — Team ID `RCVQDZ42VU`, automatic signing, version **1.0.0**
- ✅ `Info.plist` — App Store category (Productivity)
- ✅ Release build verified to compile & code-sign
- ✅ **Screenshots** — 5 images at 2560×1600 in `screenshots/en-US/`, generated
  from the app's real renderer (`screenshots/generate.mjs`)
- ✅ **Metadata** — name/subtitle/description/keywords (EN + VI) in `metadata/`
  ready for `fastlane deliver`
- ✅ **Automation** — `fastlane/` lanes + `scripts/archive-appstore.sh`
- ✅ **Privacy policy** — hosted live at **https://songha.net/markdown4w/privacy**
  (source: `privacy-policy.md`; page in the songha.net repo)

## What only you can do (Apple login required)
→ See **[`MANUAL_STEPS.md`](MANUAL_STEPS.md)** (host privacy policy, create API
key, create app record, set price = Free, run the upload).

## Files
| File | Purpose |
|------|---------|
| `MANUAL_STEPS.md` | The 5 steps that need your Apple account |
| `CHECKLIST.md` | Full step-by-step reference (incl. GUI path) |
| `listing.md` | Source copy for the store text (EN + VI) |
| `privacy-policy.md` | Privacy policy to host publicly |
| `metadata/` | `fastlane deliver` text metadata tree |
| `screenshots/en-US/` | Final App Store screenshots (2560×1600) |
| `screenshots/generate.mjs` | Regenerate screenshots: `node appstore/screenshots/generate.mjs` |
| `ExportOptions.plist` | App Store export config for the archive script |
| `../fastlane/` | Appfile · Deliverfile · Fastfile (lanes) |
| `../scripts/archive-appstore.sh` | Build/export/upload without fastlane |

## Quick start (once Apple-side prep is done)
```sh
# from the repo root
fastlane mac metadata     # push text + screenshots (no binary) to verify
fastlane mac release      # build + upload + submit for review
```
