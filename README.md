# dfcsv

パス部分とファイル名を分離してcsvで吐き出すもの。


# How to install

## Install dart

```
brew tap dart-lang/dart
brew install dart --with-content-shell
```

# Clone this repository

```
git clone https://github.com/Tsuguya/dfcsv.git
cd dfcsv
```

# Setup

```
pub get
pub global activate --source path .
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
