# Shellper

[![Ubuntu 20.04, 22.04](https://img.shields.io/static/v1?label=Ubuntu&message=20.04+|+22.04&color=blue)](https://ubuntu.com/)
[![License](https://img.shields.io/github/license/carmelosantana/shellper)](https://github.com/carmelosantana/shellper/blob/master/LICENSE)

Web centric DevOps tool box.

- [Features](#features)
- [Install](#install)
- [Uninstall](#uninstall)
- [Use](#use)
  - [Run](#run)
  - [Include](#include)
- [Examples](#examples)
  - [Quick LAMP](#quick-lamp)
- [Support](#support)
- [Funding](#funding)
- [License](#license)

[![Shellper screenshot](https://carmelosantana.com/wp-content/uploads/2022/10/Screen-Shot-2022-10-19-at-8.26.11-AM-8.png)](https://www.youtube.com/watch?v=RiqMoP9DCSU)

## Features

- Simple single file script
- Auto-complete commands via `rlwrap`
- Run local or install globally

## Install

One line install.

```bash
wget -O - https://raw.githubusercontent.com/carmelosantana/shellper/master/install.sh | sudo bash
```

---

Alternatively you can clone the repository and run Shellper locally.

```bash
git clone https://github.com/carmelosantana/shellper.git shellper
cd "shellper"
chmod +x shellper.sh
```

## Uninstall

1. [`rlwrap`](https://github.com/hanslub42/rlwrap) is the only dependency installed by [install.sh](install.sh). Uninstall with:

    ```bash
    sudo apt remove rlwrap
    ```

2. The installer copies a single script. This can easily be removed with:

    ```bash
    sudo rm /usr/local/bin/shellper
    ```

## Use

### Run

1. Run global

    ```bash
    shellper
    ```

    or local script

    ```bash
    ./shellper.sh
    ```

2. Start typing a command.

    > If installed via [install.sh](install.sh) `rlwrap` will enable auto-complete.

### Include

You can include Shellper in your existing scripts or build entirely new scripts with just Shellper functions.

```bash
#!/bin/bash
source shellper.sh
```

## Examples

### Quick LAMP

```bash
#!/bin/bash
git clone https://github.com/carmelosantana/shellper
cd shellper/examples
chmod +x install-lamp.sh
./install-lamp.sh
```

> `sudo` or root access is required for install.

Provisions a simple performance oriented PHP web server.

The following will be installed and configured:

- Add [Ondřej Surý](https://launchpad.net/~ondrej/+archive/ubuntu/php/) PPA for latest stable releases
- Apache
  - Enables `mod_event`
- PHP
- PHP-FPM
- User prompt to select MariaDB or MySQL
- Postfix

## Support

⭐ [Contact](https://github.com/carmelosantana/) for commercial support.

## Funding

If you find this project useful or use it in a commercial environment please consider donating today with one of the following options.

- [PayPal](https://www.paypal.com/donate?hosted_button_id=5RKFT8CT6DAVE)
- Bitcoin `bc1qhxu9yf9g5jkazy6h4ux6c2apakfr90g2rkwu45`
- Ethereum `0x9f5D6dd018758891668BF2AC547D38515140460f`
- Tron `TFw3D8UwduZJvx8J4FPPgPVZ2PPJfyXs3k`

## License

The code is licensed [MIT](https://opensource.org/licenses/MIT) and the documentation is licensed [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
