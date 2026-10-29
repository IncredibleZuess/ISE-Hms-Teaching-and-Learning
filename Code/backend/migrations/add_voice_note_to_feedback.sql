-- Migration: Add voice note support to feedback table
-- Date: 2025-10-08

-- Add voice note columns to feedback table
ALTER TABLE feedback
ADD COLUMN voiceNotePath VARCHAR(500) NULL COMMENT 'Path to voice note file in B2 storage',
ADD COLUMN voiceNoteFileName VARCHAR(255) NULL COMMENT 'Original filename of the voice note',
ADD COLUMN voiceNoteDuration INT NULL COMMENT 'Duration of voice note in seconds';

-- Add index for faster lookups
CREATE INDEX idx_feedback_voice_note ON feedback(voiceNotePath);
