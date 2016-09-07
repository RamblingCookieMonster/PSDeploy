# How to Contribute

Contributions to PSDeploy would be quite welcome and helpful. This page describes some ideas and guidelines around contributing.

# What Should I Contribute?

There are many ways to contribute, including:

* Open an issue for...
  * A bug you find
  * A feature you think would be valuable
  * A question on using PSDeploy (you might not be the only one with the question)
* Edit the docs to...
  * Improve or expand on [existing docs](https://psdeploy.readthedocs.org)
  * Document a deployment type
  * Write a 'How do I...' scenario
* Submit pull requests to...
  * Improve or expand on the [Readme.md](https://github.com/RamblingCookieMonster/PSDeploy/blob/master/README.md) or this Contributing.md
  * [Add or extend existing PSDeploy testing](https://github.com/RamblingCookieMonster/PSDeploy/blob/master/Tests/PSDeploy.Tests.ps1)
  * [Add a new DeploymentType](https://github.com/RamblingCookieMonster/PSDeploy/blob/master/Tests/PSDeploy.Tests.ps1)
  * Provide bug fixes, new features, cleaner code, or other improvements

# How Do I Contribute?

All of these require that you [have a GitHub account](https://github.com/signup/free).

* [Submit an issue](https://github.com/RamblingCookieMonster/PSDeploy/issues)
  * Use the search box and flip through open/closed issues to avoid duplication
  * If the issue is for a bug fix, provide reproducible code.  If you can't, and you think an issue is still warranted, provide your code, and related details on your environment
* Contribute to [the docs](https://psdeploy.readthedocs.org)
  * Fork the repo
  * Checkout and work in the dev branch (edit: use the master branch for now)
    * Organization is described in the [mkdocs.yml](https://github.com/RamblingCookieMonster/PSDeploy/blob/dev/mkdocs.yml) file. If you add a file or section, mkdocs.yml needs to know
    * mkdocs.yml points to markdown files in [the docs folder](https://github.com/RamblingCookieMonster/PSDeploy/tree/dev/docs)
    * Images are stored and accessible from docs/images
  * Commit changes
  * Submit a pull request to the dev branch
* Submit a pull request
  * Fork the repo
  * Checkout and work in the dev branch
  * Where possible, add Pester tests for your change
  * Submit your pull request to the dev branch

# Additional Resources
* [General GitHub documentation](https://help.github.com/)
* [GitHub forking documentation](https://guides.github.com/activities/forking/)
* [GitHub pull request documentation](https://help.github.com/send-pull-requests/)
* [GitHub Flow guide](https://guides.github.com/introduction/flow/)
* [GitHub's guide to contributing to open source projects](https://guides.github.com/activities/contributing-to-open-source/)

More to come, just getting this out there. Thanks to Brandon Olin for the starter .md.


