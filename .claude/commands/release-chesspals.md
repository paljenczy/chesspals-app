---
name: release-chesspals
description: Publish a new ChessPals release — bump version, tag, push, wait for CI, publish the draft GitHub Release
disable-model-invocation: false
allowed-tools: Bash(git *), Bash(gh *)
---

## Release ChessPals

Repo root: `/Users/I525520/chess-kids-app`
pubspec: `/Users/I525520/chess-kids-app/src/pubspec.yaml`

Walk through every step below in order. Do not skip steps. After each step tell the user what you did and what comes next.

---

### Step 1 — Check working tree is clean

```bash
git -C /Users/I525520/chess-kids-app status --short
```

If there are uncommitted changes, stop and tell the user to commit or stash them first. Do not proceed.

---

### Step 2 — Show current version and ask for the new one

Read the current version from `pubspec.yaml`:

```bash
grep '^version:' /Users/I525520/chess-kids-app/src/pubspec.yaml
```

The format is `version: SEMVER+BUILDNUM` (e.g. `1.0.0+1`).

Ask the user: **"Current version is X. What should the new version be?"**

Rules to explain if the user is unsure:
- Bug fixes / small tweaks → increment the last number: `1.0.0` → `1.0.1`
- New features → increment the middle number: `1.0.1` → `1.1.0`
- Major redesign → increment the first number: `1.1.0` → `2.0.0`
- The `+BUILDNUM` always increments by 1 regardless (e.g. `+3` → `+4`)

Wait for the user to provide the new version before continuing.

---

### Step 3 — Bump version in pubspec.yaml

Update `pubspec.yaml` with the new version the user provided. Use the Edit tool to change the `version:` line. Double-check the edit looks correct before continuing.

---

### Step 4 — Commit the version bump

```bash
git -C /Users/I525520/chess-kids-app add src/pubspec.yaml
git -C /Users/I525520/chess-kids-app commit -m "Bump version to vVERSION"
git -C /Users/I525520/chess-kids-app push
```

Replace VERSION with the semver part (e.g. `1.1.0`).

---

### Step 5 — Ask for release notes

Ask the user: **"What's new in this release? Describe it in plain language — this will appear in the GitHub Release that users see when they download."**

Wait for the user's answer. It can be a few bullet points or a sentence. Write it down for Step 8.

---

### Step 6 — Create and push the git tag

```bash
git -C /Users/I525520/chess-kids-app tag vVERSION
git -C /Users/I525520/chess-kids-app push origin vVERSION
```

Replace VERSION with the semver (e.g. `v1.1.0`).

Tell the user: "Tag pushed — GitHub Actions is now building the signed APK. This takes about 5 minutes."

---

### Step 7 — Wait for the CI build to succeed

Poll every 30 seconds until the workflow completes:

```bash
gh -R paljenczy/chesspals-app run list --workflow=release.yml --limit=1 --json status,conclusion,databaseId
```

- If `status` is `completed` and `conclusion` is `success` → continue to Step 8
- If `status` is `completed` and `conclusion` is `failure` → stop, show the user the failure URL:
  `https://github.com/paljenczy/chesspals-app/actions` and tell them to check the logs
- If `status` is `in_progress` or `queued` → wait 30 seconds and try again
- Timeout after 15 minutes (30 polls) — tell the user to check GitHub Actions manually

Keep the user informed: print a short "Still building… (Xm elapsed)" message each time you poll.

---

### Step 8 — Update and publish the draft release

Find the draft release ID:

```bash
gh -R paljenczy/chesspals-app release list --limit=5
```

Then update the release notes with what the user provided in Step 5 and publish it:

```bash
gh -R paljenczy/chesspals-app release edit vVERSION \
  --draft=false \
  --notes "RELEASE_NOTES"
```

Replace RELEASE_NOTES with the user's text from Step 5, formatted as markdown.

---

### Step 9 — Done

Tell the user:
- The release URL: `https://github.com/paljenczy/chesspals-app/releases/tag/vVERSION`
- The direct APK download link: `https://github.com/paljenczy/chesspals-app/releases/download/vVERSION/chesspals-vVERSION.apk`
- "Share the APK link with your friends. They download it, tap it on their Android tablet, and install."
