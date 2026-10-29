# Voice Note Feedback - Setup Guide

## Quick Start

### 1. Run Database Migration

```bash
mysql -h localhost -P 3307 -u admin -phms nwu_hms < migrations/add_voice_note_to_feedback.sql
```

This adds three new columns to the `feedback` table:
- `voiceNotePath` - B2 storage path
- `voiceNoteFileName` - File name
- `voiceNoteDuration` - Duration in seconds

### 2. Verify Environment Variables

Ensure these are set in your `.env` file:

```env
# Backblaze B2 Configuration (already configured)
B2_BUCKET_ID=612884d1abd71ef39c630212
B2_BUCKET_NAME=NWUE-HMS-TL
B2_REGION=us-east-005
B2_ENDPOINT=https://s3.us-east-005.backblazeb2.com
B2_ACCESS_KEY_ID=0051841b7e3c3220000000001
B2_SECRET_ACCESS_KEY=K005ACQGVmTyVqpd5n1lMQFTR7H7T94
B2_BUCKET_TYPE=private

# Max File Size (already configured)
MAX_FILE_SIZE=524288000  # 50MB
```

### 3. Create Upload Directory

The application will auto-create this, but you can create it manually:

```bash
mkdir -p uploads/voicenotes
```

### 4. Restart Server

```bash
npm run dev
```

## New API Endpoints

### Upload Voice Note
```bash
POST /v1/feedback/:feedbackID/voice-note
Authorization: Bearer <token>
Content-Type: multipart/form-data

Body:
- voiceNote: <audio-file>
- duration: <number> (optional)
```

### Get Voice Note
```bash
GET /v1/feedback/:feedbackID/voice-note
Authorization: Bearer <token>
```

### Delete Voice Note
```bash
DELETE /v1/feedback/:feedbackID/voice-note
Authorization: Bearer <token>
```

### Get Feedback (Enhanced)
```bash
GET /v1/feedback/:submissionID
Authorization: Bearer <token>

Returns voice note fields:
{
  "feedbackExists": "t",
  "feedbackID": 123,
  "comment": "...",
  "mark": "85",
  "voiceNotePath": "https://...",      // NEW
  "voiceNoteFileName": "...",          // NEW
  "voiceNoteDuration": 45              // NEW
}
```

## Testing

### Manual Testing with cURL

1. **Upload a voice note:**
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "voiceNote=@/path/to/audio.m4a" \
  -F "duration=30" \
  http://localhost:3000/v1/feedback/123/voice-note
```

2. **Get voice note URL:**
```bash
curl -X GET \
  -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/v1/feedback/123/voice-note
```

3. **Delete voice note:**
```bash
curl -X DELETE \
  -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/v1/feedback/123/voice-note
```

### Using Test Script

```bash
# Edit the script first to add your token and IDs
nano test-voice-note.sh

# Run tests
./test-voice-note.sh
```

## File Flow

1. **Upload:**
   - File uploaded via multipart/form-data
   - Temporarily stored in `uploads/voicenotes/`
   - Uploaded to B2 bucket (`voicenotes/` folder)
   - Database updated with file info
   - Local file deleted

2. **Retrieve:**
   - Generate signed URL from B2 (valid 1 hour)
   - Return URL to client
   - Client plays audio directly from URL

3. **Delete:**
   - Delete file from B2
   - Clear database fields (set to NULL)

## Supported Audio Formats

- MP3 (audio/mpeg)
- M4A (audio/m4a, audio/mp4, audio/x-m4a)
- WAV (audio/wav)
- WebM (audio/webm)
- OGG (audio/ogg)

## Authorization Matrix

| Endpoint | Admin | Lecturer | Student |
|----------|-------|----------|---------|
| Upload Voice Note | ✓ | ✓ | ✗ |
| Get Voice Note | ✓ | ✓ | ✓* |
| Delete Voice Note | ✓ | ✓ | ✗ |
| Get Feedback (with voice) | ✓ | ✓ | ✓* |

*Students can only access their own submissions

## Troubleshooting

### Migration fails
- Check MySQL credentials
- Verify database connection
- Check if columns already exist

### Upload fails
- Verify B2 credentials in `.env`
- Check file size (max 50MB)
- Verify file type is audio
- Check `uploads/voicenotes/` directory permissions

### Voice note URL not working
- Check B2 bucket configuration
- Verify signed URL expiration (1 hour)
- Check B2 bucket is accessible

### File not deleted from B2
- Check B2 credentials
- Verify file exists in B2
- Check B2 API logs

## Next Steps

After backend is complete and tested:

1. ✅ Update Flutter API calls (`api_calls.dart`)
2. ✅ Create audio recording widget
3. ✅ Create audio player widget
4. ✅ Update feedback widget (marking page)
5. ✅ Update feedback widget (edit page)
6. ✅ Update student feedback view
7. ✅ End-to-end testing

## Files Modified/Created

### Created:
- `migrations/add_voice_note_to_feedback.sql` - Database migration
- `VOICE_NOTE_IMPLEMENTATION.md` - Full documentation
- `VOICE_NOTE_SETUP.md` - This setup guide
- `test-voice-note.sh` - Test script

### Modified:
- `controllers/feedbackController.js` - Added voice note functions
- `routes/feedbackRouter.js` - Added voice note routes

## Support

For issues or questions:
- Check logs in `logs/feedback-*.log`
- Review error messages
- Verify B2 storage dashboard
