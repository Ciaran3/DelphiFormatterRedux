# Delphi® Formatter Redux

Bring back the classic **CTRL + D** code formatting workflow—just like the good old days (pre-Delphi 13).

**Delphi® Formatter Redux** allows you to apply your existing Delphi code formatting template with a single key combination inside the Delphi IDE.

---

## Why

Starting with **Delphi 13**, Embarcadero removed the built-in code formatter and the familiar **CTRL + D** shortcut.

This removal caused significant frustration within the Delphi community, particularly for long-time users who had built their workflow around the original formatter and its behaviour.

---

## Inspiration

This project was inspired by widespread community feedback and discussions, including:

* [https://corneliusconcepts.tech/code-formatting-delphi-13](https://corneliusconcepts.tech/code-formatting-delphi-13)
* [https://delphichops.vydevsoft.com/delphi-formatter-redux/](https://delphichops.vydevsoft.com/delphi-formatter-redux/)

---

## Features

* Restores **CTRL + D** for code formatting
* Uses the official Delphi formatter executable
* Works with existing `.config` formatting templates
* Lightweight IDE package

---

## Requirements

* **Delphi 13**
* **formatter.exe**
  Must be obtained from an older Delphi installation (for example, Delphi 12).
  *This executable is not included in this repository.*
* A Delphi formatting template file (`.config`)

---

## Installation

1. Copy your Delphi formatting template into the same directory as **DelphiFormatterRedux**
   and name it:

   ```
   Formatter.config
   ```

2. Copy `formatter.exe` into the same directory as **DelphiFormatterRedux**.

3. Open the **DelphiFormatterRedux** package in Delphi.

4. Right-click the package and select **Install**.

---

## Usage

Once installed, simply press:

```
CTRL + D
```

Your configured Delphi formatting template will be applied to the active file.

---

## Settings

By default, the formatter uses the configuration described above.

To customise file locations or names:

1. Navigate to:

   ```
   %APPDATA%\DelphiFormatterRedux
   ```

2. Edit:

   ```
   DelphiFormatterRedux.ini
   ```

3. Close and reopen Delphi for the changes to take effect.

---

## Limitations

* Applying the formatting template **modifies and saves the file immediately**.

---

## License

This project is **open source** and **free to use, modify, and redistribute**.

You are encouraged to:

* Fork the project
* Modify the source
* Use it in personal or commercial projects

No warranty is provided—use at your own risk.

---

## Trademark Disclaimer

Delphi® is a registered trademark of **Embarcadero Technologies, Inc.**

This project is an independent open source project and is **not affiliated with, endorsed by, or sponsored by Embarcadero Technologies, Inc.**

All other trademarks are the property of their respective owners.

---

## Issues and Contributions

* Please report bugs or suggestions via **GitHub Issues**
* Pull requests are welcome
