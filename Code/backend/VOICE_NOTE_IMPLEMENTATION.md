# Voice Note Feedback - Backend Implementation

## Overview
This implementation adds voice note support to the feedback system, allowing lecturers to provide audio feedback to students in addition to text comments.

## Database Changes

### Migration
Run the following migration to add voice note support to the feedback table:

```bash
mysql -h localhost -P 3307 -u admin -p nwu_hms < migrations/add_voice_note_to_feedback.sql
```

### New Columns Added to `feedback` table:
- `voiceNotePath` (VARCHAR(500), NULL) - Path to voice note file in B2 storage
- `voiceNoteFileName` (VARCHAR(255), NULL) - Original filename of the voice note
- `voiceNoteDuration` (INT, NULL) - Duration of voice note in seconds

## API Endpoints

### 1. Upload Voice Note
**POST** `/v1/feedback/:feedbackID/voice-note`

**Authorization:** Admin, Lecturer

**Request:**
- Content-Type: `multipart/form-data`
- Body:
  - `voiceNote` (file) - Audio file (mp3, m4a, wav, webm, ogg)
  - `duration` (number, optional) - Duration in seconds

**Response:**
```json
{
  "message": "Voice note uploaded successfully",
  "voiceNoteFileName": "voicenote-1234567890-123456789.m4a"
}
```

**Error Responses:**
- 400: File size exceeds limit / Invalid file type / No file provided
- 404: Feedback not found
- 500: Internal server error

---

### 2. Get Voice Note URL
**GET** `/v1/feedback/:feedbackID/voice-note`

**Authorization:** Admin, Lecturer, Student

**Response:**
```json
{
  "voiceNotePath": "https://s3.us-east-005.backblazeb2.com/file/NWUE-HMS-TL/voicenotes/voicenote-xxx.m4a?Authorization=xxx"
}
```

**Error Responses:**
- 404: Feedback not found / No voice note found
- 500: Internal server error

---

### 3. Delete Voice Note
**DELETE** `/v1/feedback/:feedbackID/voice-note`

**Authorization:** Admin, Lecturer

**Response:**
```json
{
  "message": "Voice note deleted successfully"
}
```

**Error Responses:**
- 404: Feedback not found / No voice note found
- 500: Internal server error

---

### 4. Get Feedback (Updated)
**GET** `/v1/feedback/:submissionID`

**Authorization:** Admin, Lecturer, Student (students can only view their own)

**Response:** (Updated to include voice note fields)
```json
{
  "feedbackExists": "t",
  "feedbackID": 123,
  "comment": "Great work!",
  "mark": "85",
  "voiceNotePath": "https://...",
  "voiceNoteFileName": "voicenote-xxx.m4a",
  "voiceNoteDuration": 45
}
```

## File Upload Configuration

### Supported Audio Formats
- audio/mpeg (MP3)
- audio/mp4 (MP4)
- audio/m4a (M4A)
- audio/x-m4a
- audio/wav (WAV)
- audio/webm (WebM)
- audio/ogg (OGG)

### File Size Limit
The file size limit is configured in `.env`:
```
MAX_FILE_SIZE=524288000  # 50MB
```

### Storage
- Files are temporarily stored in `uploads/voicenotes/` directory
- Files are uploaded to Backblaze B2 bucket in `voicenotes/` folder
- Local files are deleted after successful B2 upload
- Signed URLs are valid for 1 hour

## Security & Access Control

### Access Permissions
- **Upload Voice Note**: Admin, Lecturer only
- **Get Voice Note**: Admin, Lecturer, Student (students can access via feedback GET endpoint)
- **Delete Voice Note**: Admin, Lecturer only

### File Validation
- File type validation (audio only)
- File size validation (max 50MB)
- Feedback ownership validation

## Error Handling & Logging

All operations are logged using `feedbackLogger`:
- **Info**: Successful operations
- **Warn**: Missing data, validation failures
- **Error**: System errors, B2 failures

## Usage Flow

### Lecturer Adding Voice Feedback
1. Lecturer creates/updates feedback with text and mark
2. Lecturer records audio feedback
3. Frontend uploads audio file to `/v1/feedback/:feedbackID/voice-note`
4. Backend uploads to B2 and stores metadata in database
5. Student can retrieve voice note when viewing feedback

### Student Viewing Voice Feedback
1. Student requests feedback via `/v1/feedback/:submissionID`
2. Backend returns feedback including voice note signed URL (if exists)
3. Student can play audio directly from signed URL

### Lecturer Updating Voice Feedback
1. Lecturer uploads new voice note to existing feedback
2. Backend automatically deletes old voice note from B2
3. New voice note is uploaded and metadata updated

### Lecturer Deleting Voice Feedback
1. Lecturer requests deletion via `/v1/feedback/:feedbackID/voice-note`
2. Backend deletes file from B2 and clears database fields

## Testing Checklist

- [ ] Run database migration successfully
- [ ] Test voice note upload with valid audio file
- [ ] Test voice note upload with invalid file type
- [ ] Test voice note upload exceeding size limit
- [ ] Test voice note retrieval (lecturer)
- [ ] Test voice note retrieval (student)
- [ ] Test voice note deletion
- [ ] Test uploading new voice note (replaces old one)
- [ ] Verify B2 storage cleanup
- [ ] Verify signed URL generation
- [ ] Test authorization (students cannot upload/delete)

## Dependencies
- `multer@1.4.5-lts.1` - File upload handling
- `backblaze-b2@1.7.0` - B2 storage integration
- Existing: `fs`, `path`, `dotenv`

## Notes
- Voice notes are optional; feedback can exist without voice notes
- Old voice notes are automatically deleted when replaced
- Signed URLs expire after 1 hour for security
- B2 bucket is configured for private access with signed URLs
