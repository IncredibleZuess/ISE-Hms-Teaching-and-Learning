-- Migration: Add feedback viewed tracking
-- Description: Adds columns to track when students view their feedback
-- Date: 2025-10-07

-- Add feedbackViewed column to track if student has viewed their feedback
ALTER TABLE feedback
ADD COLUMN feedbackViewed BOOLEAN DEFAULT FALSE;

-- Add viewedAt column to track when the feedback was viewed
ALTER TABLE feedback
ADD COLUMN viewedAt TIMESTAMP NULL DEFAULT NULL;

-- Add index for better query performance
CREATE INDEX idx_feedback_viewed ON feedback(feedbackViewed);

-- Update existing feedback records to set feedbackViewed to FALSE
UPDATE feedback SET feedbackViewed = FALSE WHERE feedbackViewed IS NULL;
