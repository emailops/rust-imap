# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added

### Changed

### Removed

## emailops/2.4-panic-free
Fork of 2.4.1 kept for [EmailOps](https://github.com/emailops/emailops): `main` is the 3.0 alpha
line, and upstream's fix for the first item below only landed there.

### Changed
- A completion for another command returns `Error::TagMismatch` instead of panicking
  ([#284](https://github.com/jonhoo/rust-imap/pull/284)). The number-only `Display` and refusing
  later commands are specific to this branch.
- An untagged line the parser rejects no longer abandons the response
  ([#211](https://github.com/jonhoo/rust-imap/issues/211)). It stays in the raw response, the rest
  of the response is read, and a typed command returns `Error::Parse` once the session is back in
  step.
- A rejected line that announces a literal, or that is no IMAP response at all, ends the response
  and the session: what follows can be message text, so later commands return
  `Error::ConnectionLost` without writing to the stream.
- `Error::Parse(ParseError::Invalid)` from reading a response starts at the rejected line.
- An untagged `NO`, `BAD` or `BYE` during `SELECT` or `EXAMINE`, and a tagged completion of `IDLE`
  without a continuation, no longer reach `unreachable!()`.

## [2.4.1] - 2021-01-12
### Changed

 - Handle empty-set inputs to `fetch` and `uid_fetch` (#177)

## [2.4.0] - 2020-12-15
### Added

 - `append_with_flags_and_date` (#174)

## [2.3.0] - 2020-08-23
### Added

 - `append_with_flags` (#171)

## [2.2.0] - 2020-07-27
### Added

 - Changelog
 - STARTTLS example (#165)
 - Timeout example (#168)
 - Export `Result` and `Error` types (#170)

### Changed

 - MSRV increased
 - Better documentation of server greeting handling (#168)

[Unreleased]: https://github.com/jonhoo/rust-imap/compare/v2.4.1...HEAD
[2.4.1]: https://github.com/jonhoo/rust-imap/compare/v2.4.0...v2.4.1
[2.4.0]: https://github.com/jonhoo/rust-imap/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/jonhoo/rust-imap/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/jonhoo/rust-imap/compare/v2.1.2...v2.2.0
