# INTO Remote

Remote support client of [INTO d.o.o. Beograd](https://www.intomsp.com), used by our technicians to help customers on their computers.

INTO Remote is a customized build of [RustDesk](https://github.com/rustdesk/rustdesk). It is **not** an official RustDesk product and is not affiliated with or endorsed by the RustDesk authors.

## What is changed

Everything we change is in this repository, nothing else:

| File | Purpose |
|---|---|
| `branding/apply.sh` | patches applied on top of the unmodified RustDesk source (name, icon, links, our rendezvous server, no upstream update prompts) |
| `branding/config.env` | name, links, server address and server public key |
| `branding/custom-client.json` | settings of the public client (it can only receive connections) |
| `branding/icon.*` | application icon |
| `.github/workflows/build-windows.yml` | reproducible build on GitHub Actions |

## Source code

The complete corresponding source is the RustDesk source at the tag named in `branding/config.env` (`RUSTDESK_VERSION`) with `branding/apply.sh` applied:

```
git clone --recursive --branch 1.4.9 https://github.com/rustdesk/rustdesk
cd rustdesk && bash ../into-remote/branding/apply.sh
```

## License

AGPL-3.0, same as RustDesk. See `LICENSE`. RustDesk is copyright of Purslane Tech Pte. Ltd. and its contributors.

## Security

The client accepts a session only when the person at the computer approves it or shares the one-time password. Report problems to office@intomsp.com.
