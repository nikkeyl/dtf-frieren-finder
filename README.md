# DTF Frieren Finder

![AI](https://img.shields.io/badge/AI-red)

AI-assisted shell automation for the first post tagged `#иногдафрирен` in the
[Lxix DTF feed](https://dtf.ru/lx_ix). No AI model runs in the automation.

## Run

Requires a POSIX shell, `curl`, `jq` and `mktemp`.

```sh
sh parser.sh
```

Local runs download images only. The script prints a new temporary directory;
set `TARGET_DIR` to choose another location. `SUBSITE_URI` and `TAG` are defined
in `parser.sh`.

## Email configuration

Enable GitHub Actions in your fork and set `MAIL_USERNAME` to an iCloud Mail
address and `MAIL_PASSWORD` to its app-specific password. The workflow sends to
that address through `smtp.mail.me.com:587` and needs `contents: write` to
update `last_sent.txt`. Review inherited history before the first run.

Schedule: `0 * * * *` (hourly, UTC); actual timing depends on GitHub Actions.
Manual workflow dispatch is disabled.

## Decisions and files

- `parser.sh` paginates the DTF API until the first matching post. It does not
  process every unseen post or recognize image content.

- `.github/workflows/fetcher-photos.yaml` selects unseen filenames, emails them
  and commits only `last_sent.txt` after successful delivery. Runs are
  serialized.

- Images and attachments stay outside the checkout in temporary directories.
  Git-backed filename history avoids a separate database; an email followed by a
  failed history push can be sent again.

- Downloads use UUID filenames with `.jpg` extensions without format conversion.

## License

Source code: [MIT](LICENSE). Downloaded DTF images are third-party content,
excluded from MIT and subject to their rights holders' terms. They are not
stored in the repository tree.
