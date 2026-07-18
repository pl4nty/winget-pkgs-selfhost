Checklist for Pull Requests

- [ ] Is there a related issue or pull request in [winget-pkgs](https://github.com/microsoft/winget-pkgs)? If so, add the link(s) below.
   <!-- Example: Resolves #328283 -->
  - Relates to microsoft/winget-pkgs#[Issue Number]

Manifests

- [ ] Have you checked that there aren't other open pull requests for the same manifest update/change?
- [ ] Have you [validated](https://github.com/microsoft/winget-pkgs/blob/master/doc/Authoring.md#validation) your manifest locally with `winget validate --manifest <path>`?
- [ ] Have you tested your manifest locally with `winget install --manifest <path>`?
- [ ] Does your manifest conform to the [1.28 schema](https://github.com/denelon/winget-pkgs/tree/docs/manifest-schema-1.28.0/doc/manifest/schema/1.28.0)?

Note: `<path>` is the directory's name containing the manifest you're submitting.

---
