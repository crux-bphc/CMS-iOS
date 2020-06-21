# CMS-iOS

This is the iOS version on the CMS app, written in Swift. The app utilises the API endpoints provided by Moodle from the server hosted on the [CMS Website](https://td.bits-hyderabad.ac.in/moodle/).

[Download on the App Store](https://apps.apple.com/in/app/cms-bphc/id1489946522)
  
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/dwyl/esta/issues)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- Token based as well as **Google** login.
- Offline access to course contents.
- Enrolment to new courses.
- Local storage of attachments for external access from Files app.

## Installation

The deployment target for the app is iOS 11.0, so if your device is not on that or a newer version, you're out of luck `¯\_(ツ)_/¯` 

You can download the latest release of the app from the App Store [here](https://apps.apple.com/in/app/cms-bphc/id1489946522).

If you want to manually install the app from this repository, first clone it. Navigate to project directory and then install the pods by executing `pod install`. Once pods have been installed successfully, open the file named `CMS-iOS.xcworkspace` and then change the development profile to your profile and then run it after selecting your device from the drop-down next to the run button.

## Contributing

You can contribute by submitting an issue, or by picking an existing one from the list and sending a PR. Ensure that the branch underlying the PR is up-to-date with latest changes.

All changes must be made on top of a new branch forked off the `development` branch. The `master` branch is only updated when a new release is made.

Commit messages should follow common guidelines, such as the ones mentioned [here](https://chris.beams.io/posts/git-commit/), whenever possible.

Mention keywords such as "Fixes" or "Closes" in commit messages, followed by the issue number, to automatically close corresponding issues. [(List of keywords)](https://help.github.com/articles/closing-issues-using-keywords/)

The Moodle endpoints used by this app have been collected in a [Postman](https://getpostman.com") [here](https://www.getpostman.com/collections/207390c4552febe4e393). You may import this collection into Postman directly using the link. 
## License

The app is under the MIT License.
