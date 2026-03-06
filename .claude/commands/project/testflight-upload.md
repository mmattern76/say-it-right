---
description: Build, archive, and upload Say it right! to TestFlight
---
Run the TestFlight upload script. This bumps the build number, archives a
Release build, exports the IPA, and uploads to App Store Connect.

```bash
./scripts/testflight-upload.sh
```

If the build or upload fails, diagnose the error and suggest a fix.
After a successful upload, remind the user that processing takes a few
minutes before the build appears in TestFlight.
