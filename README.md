[![Build Status](https://travis-ci.org/Tsuguya/dfcsv.svg)](https://travis-ci.org/Tsuguya/dfcsv)

# dfcsv

パス部分とファイル名を分離してcsvで吐き出すもの。


# How to install

## Install dart

```
brew tap dart-lang/dart
brew install dart --with-content-shell
```

# Setup

```
pub get
pub global activate --source git https://github.com/Tsuguya/dfcsv.git
```

## Add dart PATH to your rc file.

```
echo 'export PATH="$PATH":"~/.pub-cache/bin"' >> ~/.bashrc
```

## Reload

```
source ~/.bashrc
```

or just restart your shell
