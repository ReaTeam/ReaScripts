## Commit Verification
All commits are GPG-signed with Key ID: : `9027C715270B8459` or `E73A4164C4E8BACA` or `BFCDF1CC0C66D829`
- Web commits use GitHub's flow key.
### Verify commits:
```bash
gpg --keyserver keys.openpgp.org --recv-keys 9027C715270B8459
git log --show-signature
```
Alternative check:
```bash
gpg --keyserver https://flaneurette.com/.well-known/flaneurette.pub --recv-keys 9027C715270B8459
git log --show-signature
```
Note: GPG may show a trust warning - this is normal until you explicitly trust the key.
### Security
- The Web (flow) interface commits may be less secure if GitHub was compromised at that moment of committing.
- Older packages may have old GitHub signing key, this is expected. GitHub keys rotate often.
- To be certain use this permalink for webcommits: https://github.com/web-flow.gpg
- VERIFY.md GPG key verification files have been added to all packages since 11 January 2026.
- Last update: 4:26PM, GMT-1. 2/July/2026.

