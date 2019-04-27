# p2psec-enroll

A client for the enrollment protocol of the P2P Systems and Security course at TUM written in Swift 5.

This wont run on Linux because I used the macOS CommonCrypto lib for performance reasons instead of the CryptoSwift library. One could use [BlueCryptor](https://github.com/IBM-Swift/BlueCryptor) for OpenSSL bridging on Linux but using it impacted performance on macOS so I opted against it since I don't have access to a powerful Linux machine anyway. 

## Building and running

To build & run, simply execute `swift run -c release`.

## Performance

Performance is not that great with ~0.61 MH/s on a 2017 Macbook Pro (Intel Core I7-7820HQ Kaby Lake @ 2.9 GHz) utilizing all 8 logical cores with otherwise idle load.

## License

Licensed under GPL v3
