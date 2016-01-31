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

## Test

* The test was designed by following contents in [How data encryption software creates one way hash files using the sha1 hashing algorithm.](http://www.metamorphosite.com/one-way-hash-encryption-sha1-data-software).
* How to run
    * `./sha1.test.sh`

## References

* [How data encryption software creates one way hash files using the sha1 hashing algorithm.](http://www.metamorphosite.com/one-way-hash-encryption-sha1-data-software)
* 結城浩. 新版暗号技術入門: 秘密の国のアリス. SB クリエイティブ株式会社, 2008.
* [SHA-1の計算方法 - BK class](http://bkclass.web.fc2.com/doc_sha1.html)

## License

See `LICENSE`.
