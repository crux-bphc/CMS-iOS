# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2021-01-12
### Added
- Support for CMS on AWS by adding new base URL.

### Removed
- Notifications using background fetch.

## [1.1] - 2020-08-23
### Added
- Ability to search for modules and courses on Dashboard itself
- Redesigned Extras Tab
- Semester Label in Dashboard cell
- Option to hide semester label
- System spotlight search indexing for courses
- Realm Migration Block for future use

### Fixed
- Colors of cells in Light Mode on Dashboard to be more streamlined with the rest of the UI
- Crash when the app is opened using URL Schemes as it would previously work only with Login With Google
- Small titles for courses
- Incorrect Regex parsing for some courses
- HTML entities showing up in action sheet
- Infinitely loading refresh control on course contents when offline
- Bug where course contents would show up in incorrect order while offline
- Color Allotment blocking main thread and leading to lag on Dashboard
- Bug where user would sometimes by spammed with notifications
- Crash on opening the app using URL schemes

### Removed
- Inconsistent and buggy table view animation

## [1.0.1] - 2020-02-19
### Added
- Support for viewing forum module description
### Fixed
- Crash on downloading modules on iOS 13
- HTML entities showing up on course content page
