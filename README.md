# DTF Frieren Finder

![AI](https://img.shields.io/badge/AI-red)

A shell script that finds DTF posts tagged `#иногдафрирен`, downloads their
images, and emails new images through GitHub Actions.

## Overview

The project checks the [Lxix feed on DTF](https://dtf.ru/lx_ix) for the first
matching post in the newest-first timeline. It downloads the post's images
and uses a scheduled workflow to email files absent from the sent-file history.

## Features

- Fetches posts through the DTF API using `curl` and `jq`.
- Follows timeline pagination until it finds a matching post or reaches the end.
- Saves images to `frieren_photos/`, using their UUIDs as filenames.
- Tracks previously sent filenames in `last_sent.txt`.
- Supports scheduled and manual runs through GitHub Actions.

## Getting started

### Run the downloader locally

Requirements: Git, a POSIX shell, `curl`, and `jq`.

```sh
git clone https://github.com/nikkeyl/dtf-frieren-finder.git
cd dtf-frieren-finder
sh parser.sh
```

Images are saved to `frieren_photos/`. Running the script locally downloads
images only; email delivery and sent-file tracking belong to the workflow.

### Configure email delivery

In your own repository or fork:

1. Enable GitHub Actions.

1. Add the repository secrets `MAIL_USERNAME` and `MAIL_PASSWORD`.

1. Use an iCloud Mail address for `MAIL_USERNAME` and an app-specific password
   for `MAIL_PASSWORD`.

1. Allow the workflow to write repository contents so it can commit downloaded
   images and sent-file history.

1. Open **Actions → Fetch Photos → Run workflow** to test a manual run.

The workflow connects to `smtp.mail.me.com` on port `587` and sends mail
to the address stored in `MAIL_USERNAME`. To use a different provider or
recipient, update `.github/workflows/fetcher-photos.yaml`.

See Apple's [iCloud Mail server settings](https://support.apple.com/en-us/102525)
for the SMTP authentication requirements.

Before the first run in a fork, review `frieren_photos/` and `last_sent.txt`:
the inherited files and history affect which images are considered new.

The schedule is `0 * * * *`: once per hour, at minute zero, in UTC.
Actual execution depends on GitHub Actions scheduling and workflow availability.

## Implementation

The work is split between two files:

- `parser.sh` resolves the DTF subsite, reads the timeline, finds the first
  matching post, and downloads its images.

- `.github/workflows/fetcher-photos.yaml` selects files missing from
  `last_sent.txt`, sends them as attachments, and commits the updated state.

The feed, tag, and download directory are configured by constants near the
top of `parser.sh`: `SUBSITE_URI`, `TAG`, and `TARGET_DIR`.
If you change the download directory, update the workflow paths as well.

Git stores both the downloaded images and delivery history, avoiding a
separate database. The AI badge identifies AI-assisted development; the
automation itself uses API requests and string matching, without an AI model.

## Trade-offs and limitations

- Each run processes the first matching post, rather than every unseen post.

- Matching checks whether text in a post's blocks contains the tag string;
  it does not classify images or recognize Frieren visually.

- The script depends on the current DTF API and image-host response formats.

- Images accumulate in Git, increasing repository size over time.

- Filename tracking is not an exactly-once delivery guarantee. A successful
  email followed by a failed Git push can lead to a repeated notification.

- Downloaded files use a `.jpg` extension without image-format conversion.

## Verification

Check shell syntax without making network requests:

```sh
sh -n parser.sh
```

For an end-to-end check, run the workflow manually and inspect the downloaded
files, email attachments, and commit updating `last_sent.txt`.
If the next run finds no new filenames, it should skip email delivery.

The repository does not currently include an automated parser test suite.

## License

[MIT](./LICENSE)
