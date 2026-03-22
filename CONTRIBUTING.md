# Contributing

Contributions are welcome! Whether it's a bug report, feature request, documentation improvement, or code change, we appreciate your help.

## Reporting Bugs

Please [open an issue](https://github.com/headwalluk/rpusbdisp/issues/new?template=bug_report.md) and include:

- **Kernel version**: `uname -r`
- **Distribution and version**: e.g. Debian 12, Raspberry Pi OS Bookworm
- **Architecture**: `uname -m`
- **USB display info**: `lsusb | grep -i fccf`
- **Relevant dmesg output**: `dmesg | grep -i rp`
- **Steps to reproduce** the issue

The more detail you provide, the easier it is to diagnose.

## Submitting Changes

1. Fork the repository and create a branch from `master`.
2. Make your changes. If you're modifying the kernel driver, test that it compiles cleanly with `make modules` in `drivers/linux-driver/`.
3. If you're adding a new feature, consider adding documentation in `docs/` or a sample in `samples/`.
4. Open a pull request with a clear description of what you changed and why.

## Development Setup

See [docs/building-debian-amd64.md](docs/building-debian-amd64.md) for build instructions. You'll need kernel headers and `build-essential` at minimum.

## Code Style

- Kernel driver code follows the [Linux kernel coding style](https://www.kernel.org/doc/html/latest/process/coding-style.html).
- Sample programs should be simple and well-commented -- they serve as documentation.

## License

By contributing, you agree that your contributions will be licensed under the [GPLv2](LICENSE).
