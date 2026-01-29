[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Delphi Version](https://img.shields.io/badge/Delphi-13+-orange.svg)]()
[![Formatter](https://img.shields.io/badge/Formatter-CTRL%2BD-green.svg)]()

# Delphi Formatter Redux

**Bring back the classic CTRL + D code formatting workflow** — just like the good old days (pre‑Delphi 13).  

**Delphi Formatter Redux** lets you apply your existing Delphi code formatting template with a single key combination inside the Delphi IDE.

---

## Why This Exists

Starting with **Delphi 13**, Embarcadero removed the built‑in code formatter and the familiar **CTRL + D** shortcut.

This removal caused significant frustration in the Delphi community — especially for long‑time users who built their workflow around the original formatter’s behaviour.

This project was inspired by community discussion and feedback:

- https://corneliusconcepts.tech/code-formatting-delphi-13  
- https://delphichops.vydevsoft.com/delphi-formatter-redux

---

## Features

- Restores **CTRL + D** for code formatting  
- Uses the official Delphi formatter executable  
- Works with existing `.config` formatting templates  
- Lightweight IDE package  

---

## Requirements

- **Delphi 13**
- **formatter.exe** — This must be obtained from an older Delphi installation (for example, Delphi 12)  
  > This executable is **not included** in this repository.
  > 
  > By default it will be located at: C:\Program Files (x86)\Embarcadero\Studio\23.0\bin
- A Delphi formatting template file (`.config`)

---

## Installation

1. Copy your Delphi formatting template into the same directory as DelphiFormatterRedux and name it:
   ```
   Formatter.config
   ```
2. Copy `formatter.exe` into the same directory.
3. Open **DelphiFormatterRedux** in Delphi.
4. Right click the package and select **Install**.

---

## Usage

Once installed, simply press:

```
CTRL + D
```

Your configured Delphi formatting template will be applied to the active editor file.

---

## Settings

By default, the standard configuration is used.

To customise the location of **formatter.exe** or **Formatter.config**, navigate to:

```
%APPDATA%\DelphiFormatterRedux
```

Edit the following file:

```
DelphiFormatterRedux.ini
```

Restart Delphi for changes to take effect.

---

## Limitations

- Applying the code formatting **saves the active file immediately**.

---

## License

This project is **open source** and **free to use, modify, and redistribute**.

You are free to:
- Modify the source
- Fork the repository
- Use it in personal or commercial projects

No warranty is provided — use at your own risk.

---

## Trademark Disclaimer

**Delphi®** is a registered trademark of *Embarcadero Technologies, Inc.*

This project is an independent open source effort and is **not affiliated with, endorsed by, or sponsored by Embarcadero Technologies, Inc.**  
All other trademarks are the property of their respective owners.

---

## Issues & Contributions

Feedback, bug reports, and pull requests are welcome.

Please open an issue or submit a pull request on GitHub.

---
