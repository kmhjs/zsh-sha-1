# Zsh-SHA-1

This project is to implement SHA-1 algorithm in Z-shell.

## Normal version and Binary version

This project has 2 versions; normal and binary version.  
Originally, the project was created as binary version, and ported to normal version.

Main difference is that the value is treated as binary string or not.

## Requirements

* `zsh`
    * Tested with `zsh 5.2 (x86_64-apple-darwin15.0.0)`
* `printf`

## Usage

* Normal version

```
target_string='Input string'

source sha1.sh
sha1::main ${target_string}
```

* Binary version

```
target_string='Input string'

source sha1.binary.sh
sha1::main ${target_string}
```

## Test

* The test was designed by following contents in [How data encryption software creates one way hash files using the sha1 hashing algorithm.](http://www.metamorphosite.com/one-way-hash-encryption-sha1-data-software).
* How to run
    * `./sha1.test.sh`
    * `./sha1.binary.test.sh`

## Note

* Normal version is faster than binary one.
* In Normal version, the value expressed in more than 32-bits is treated in binary notation (e.g. 512-bits).

## References

* [How data encryption software creates one way hash files using the sha1 hashing algorithm.](http://www.metamorphosite.com/one-way-hash-encryption-sha1-data-software)
* 結城浩. 新版暗号技術入門: 秘密の国のアリス. SB クリエイティブ株式会社, 2008.
* [SHA-1の計算方法 - BK class](http://bkclass.web.fc2.com/doc_sha1.html)

## License

See `LICENSE`.
