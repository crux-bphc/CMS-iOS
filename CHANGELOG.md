# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.1] - Unreleased

### Fixed
- Crash on long-pressing a module or discussion on Dashboard during search
- HTML2String function, that caused issues on Site News page


## [1.3] - 2021-08-22

### Fixed
- Fixed unenrollment process, removed need for sign in through web view using a private token obtained during Google Login

### Removed
- Semester label in Dashboard cell and option to show/hide it

## [1.2] - 2021-01-17

### Added
- Support for push notifications
- Redirection to module/discussion when notifications are clicked
- Unenrolling feature
- Support for adding image of timetable
- Quick loading of cached discussions and site news
- Refresh control for discussions
- View models for cells of Dashboard courses, discussions and site news

### Fixed
- Random numbers showing up in Dashboard course cell badges
- Some course discussions being marked unread after reloading site news due to matching ids


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
