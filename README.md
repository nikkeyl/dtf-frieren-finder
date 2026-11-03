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
- Downloads images to a temporary directory, using their UUIDs as filenames.
- Tracks previously sent filenames in `last_sent.txt`.
- Runs on an hourly schedule through GitHub Actions.

## Getting started

### Run the downloader locally

Requirements: Git, a POSIX shell, `curl`, `jq`, and `mktemp`.

```sh
git clone https://github.com/nikkeyl/dtf-frieren-finder.git
cd dtf-frieren-finder
sh parser.sh
```

By default, images are saved to a new system temporary directory. The script
prints its path. Set `TARGET_DIR` to choose another download location. Running
locally downloads images only; email delivery and sent-file tracking belong to
the workflow.

### Configure email delivery

In your own repository or fork:

1. Enable GitHub Actions.

1. Add the repository secrets `MAIL_USERNAME` and `MAIL_PASSWORD`.

1. Use an iCloud Mail address for `MAIL_USERNAME` and an app-specific password
   for `MAIL_PASSWORD`.

1. Allow the workflow to write repository contents so it can update
   `last_sent.txt` after a successful email.

The workflow connects to `smtp.mail.me.com` on port `587` and sends mail
to the address stored in `MAIL_USERNAME`. To use a different provider or
recipient, update `.github/workflows/fetcher-photos.yaml`.

See Apple's [iCloud Mail server settings](https://support.apple.com/en-us/102525)
for the SMTP authentication requirements.

Before the first run in a fork, review `last_sent.txt`: the inherited delivery
history determines which filenames are considered new.

The schedule is `0 * * * *`: once per hour, at minute zero, in UTC.
Actual execution depends on GitHub Actions scheduling and workflow availability.

## Implementation

The work is split between two files:

- `parser.sh` resolves the DTF subsite, reads the timeline, finds the first
  matching post, and downloads its images.

- `.github/workflows/fetcher-photos.yaml` selects files missing from
  `last_sent.txt`, sends them as attachments, and commits only the delivery
  history after the email succeeds.

The feed and tag are configured near the top of `parser.sh` through
`SUBSITE_URI` and `TAG`. The `TARGET_DIR` environment variable controls the
download location. In GitHub Actions, downloads and attachments use
`runner.temp` directories outside the repository checkout.

Git stores delivery history only, avoiding a separate database. Downloads and
email attachments remain in the runner's temporary directories and are never
staged by the workflow. Scheduled runs are serialized to avoid concurrent
updates to the sent-file history.

The AI badge identifies AI-assisted development; the automation itself uses
API requests and string matching, without an AI model.

## Trade-offs and limitations

- Each run processes the first matching post, rather than every unseen post.

- Matching checks whether text in a post's blocks contains the tag string;
  it does not classify images or recognize Frieren visually.

- The script depends on the current DTF API and image-host response formats.

- Downloaded images are not archived by the workflow; the runner removes its
  temporary files after the job. Local runs leave downloads in the selected
  temporary or custom directory.

- Filename tracking is not an exactly-once delivery guarantee. A successful
  email followed by a failed Git push can lead to a repeated notification.

- Downloaded files use a `.jpg` extension without image-format conversion.

## License

The source code is licensed under [MIT](./LICENSE).

Images downloaded from DTF are third-party content and are excluded from the
MIT license. Their use remains subject to the rights holders' terms. Downloaded
images are not stored in the current repository tree.
