# Zsh-SHA-1

This project is to implement SHA-1 algorithm in Z-shell.

## Requirements

* `zsh`
    * Tested with `zsh 5.2 (x86_64-apple-darwin15.0.0)`
* `printf`

## Usage

```
target_string='Input string'

source sha1.sh
sha1::main ${target_string}
```

## References

* [How data encryption software creates one way hash files using the sha1 hashing algorithm.](http://www.metamorphosite.com/one-way-hash-encryption-sha1-data-software)
* 結城浩. 新版暗号技術入門: 秘密の国のアリス. SB クリエイティブ株式会社, 2008.

## License

See `LICENSE`.
