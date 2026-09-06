# Cloudinary evidence setup

MineSafe stores only image/video (and the existing document-upload flow's raw
files) in Cloudinary. Firebase remains responsible for Authentication and
Firestore report metadata. Never put a Cloudinary `api_secret`, backend signing
secret, service-account key, or other server credential in this repository or
APK.

## Demo: unsigned upload preset

1. Create a Cloudinary product environment and copy its **cloud name**.
2. Create an **unsigned** upload preset dedicated to MineSafe development.
3. Restrict permitted formats to `jpg`, `jpeg`, `png`, `webp`, `mp4`, and the
   document formats your policy allows. Set size limits appropriate for field
   devices.
4. Restrict the preset's folder/path policy to the `minesafe/` namespace where
   supported. The app creates deterministic public IDs:
   `minesafe/{mineId}/{reportType}/{submissionId}/{evidenceId}`.
5. Run the app without committing any configuration:

   ```powershell
   flutter run --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name --dart-define=CLOUDINARY_UNSIGNED_UPLOAD_PRESET=minesafe_mobile_demo
   ```

6. Capture an image and a video, submit while online, and verify that the
   Cloudinary Media Library contains the deterministic public ID. Confirm the
   Firestore report contains only metadata (`secure_url`, `storage_path`, hash,
   type, and capture location), never binary bytes.

## Production: signed uploads

Prefer a trusted backend signing endpoint. Configure its URL with:

```powershell
--dart-define=MEDIA_SIGNING_ENDPOINT=https://api.example.gov/media/sign
```

The endpoint must authenticate the inspector, authorize the mine/report,
generate a short-lived Cloudinary signature, and own deletion. The mobile app
must never receive or store the Cloudinary API secret. The current client keeps
this seam explicit; the endpoint response contract is intentionally pending
backend-team approval.

## Operational checks

- Test offline capture: evidence stays local with `pending` status.
- Test retry: stable `EV-...` IDs and Cloudinary public IDs prevent duplicate
  uploads.
- Test an upload that succeeds before Firestore fails: the next retry must
  reuse the stored Cloudinary URL instead of uploading again.
- Dashboard access should use a trusted backend/Admin SDK. Inspector Firestore
  rules intentionally do not grant cross-inspector dashboard reads.
