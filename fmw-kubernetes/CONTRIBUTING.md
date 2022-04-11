# Contributing
Oracle welcomes contributions to this repository from anyone.

If you want to submit a pull request to fix a bug or enhance an existing file, please first open an issue and link to that issue when you submit your pull request.

If you have any questions about a possible submission, feel free to open an issue too.

## Contributing to the Oracle Fusion Middleware Kubernetes repository

Pull requests can be made under [The Oracle Contributor Agreement](https://www.oracle.com/technetwork/community/oca-486395.html) (OCA).

For pull requests to be accepted, the bottom of your commit message must have the following line using your name and e-mail address as it appears in the OCA Signatories list.

```
Signed-off-by: Your Name <you@example.org>
```

This can be automatically added to pull requests by committing with:

```
  git commit --signoff
```

Only pull requests from committers that can be verified as having signed the OCA can be accepted.

## Oracle Product Ownership and Responsibility

For any new product content, *you must obtain internal Oracle approvals for the distribution of this content prior to submitting a pull request*. If you are unfamiliar with the approval process to submit code to an existing GitHub repository, please contact the [Oracle Open Source team](mailto:opensource_ww_grp@oracle.com) for details.

The GitHub user who submits the initial pull request to add new Kubernetes scripts should add themselves to the [code owner](./CODEOWNERS) file in that same request. This will flag the user as the owner of the content and any future pull requests that affect the conten will need to be approved by this user.

The code owner will also be assigned to any issues relating to their content.

You must ensure that you check the [issues](https://github.com/oracle/fmw-kubernetes/issues) on at least a weekly basis, though daily is preferred.

If you wish to nominate additional or alternative users, they must be a visible member of the [Oracle GitHub Organisation](https://github.com/orgs/oracle/people/).

Contact [Rupesh Das](https://github.com/rdas0405) for more information.

### Pull request process

1. Fork this repository
2. Create a branch in your fork to implement the changes. We recommend using the issue number as part of your branch name, e.g. `1234-fixes`
3. Ensure that any documentation is updated with the changes that are required by your fix.
4. Ensure that any dependancies are updated if any scripts are changed.
5. Submit the pull request. *Do not leave the pull request blank*. Explain exactly what your changes are meant to do and provide simple steps on how to validate your changes. Ensure that you reference the issue you created as well.
We will assign the pull request to 2-3 people for review before it is merged.

*Copyright (c) 2020 Oracle and/or its affiliates.*