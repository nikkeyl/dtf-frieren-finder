# DTF Frieren Finder

![AI](https://img.shields.io/badge/AI-red)

A shell script that downloads images from the first post containing
`#иногдафрирен` in the [Lxix DTF feed](https://dtf.ru/lx_ix). A scheduled
GitHub Actions workflow emails images whose filenames are absent from its
send history.

The project was built with AI assistance. It does not run an AI model.

## Download locally

Install `curl` and `jq`, then run the script with a POSIX shell. It also
uses `mktemp` and standard shell utilities.

```sh
sh parser.sh
```

The script prints the temporary directory containing the downloads. To
choose the destination yourself:

```sh
TARGET_DIR=/path/to/downloads sh parser.sh
```

Local execution only downloads images. Change `SUBSITE_URI` and `TAG` in
`parser.sh` to use another feed or search string. Matching uses a text
substring in the post blocks.

## Configure email

In a fork, enable GitHub Actions and configure these repository secrets:

| Secret          | Value                                        |
| --------------- | -------------------------------------------- |
| `MAIL_USERNAME` | Your iCloud Mail address; also the recipient |
| `MAIL_PASSWORD` | An app-specific password for that account    |

`.github/workflows/fetcher-photos.yaml` uses `smtp.mail.me.com:587` and runs
on `0 * * * *` (hourly, UTC). GitHub may delay scheduled runs. Manual
dispatch is disabled.

The workflow needs `contents: write` to update `last_sent.txt`. Review that
file before enabling the schedule in a fork: inherited entries suppress
filenames already in the history.

## Delivery and storage

The parser paginates until it finds the first matching post. It does not
collect all posts missed between runs. Image files use UUID names and a
`.jpg` extension without format conversion.

The workflow serializes runs and keeps downloads and attachments in
temporary directories outside the checkout. After a successful email step it
commits `last_sent.txt`, which avoids a separate database.

> [!WARNING]
>
> If sending succeeds but the history push fails, a later run can send the
> same images again. SMTP acceptance does not confirm inbox delivery.

## License

The source code uses [MIT](LICENSE). Downloaded DTF images belong to third
parties and are excluded from that license. They are not stored in the
current repository tree; their use remains subject to the rights holders'
terms.
