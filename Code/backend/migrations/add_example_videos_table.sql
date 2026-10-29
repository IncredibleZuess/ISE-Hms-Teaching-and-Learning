-- Migration: Add example_videos table for Phase 2
-- Date: 2026-09-14

CREATE TABLE IF NOT EXISTS example_videos (
  id INT NOT NULL AUTO_INCREMENT,
  assignment_id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  minio_key VARCHAR(500) NOT NULL COMMENT 'Object key in example-videos MinIO bucket',
  minio_path VARCHAR(1000) NULL COMMENT 'Public or signed playback path',
  file_size BIGINT NULL COMMENT 'File size in bytes',
  uploaded_by INT NULL COMMENT 'users.userID',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_example_videos_assignment (assignment_id),
  CONSTRAINT ev_assignment FOREIGN KEY (assignment_id) REFERENCES assignment(assignmentID) ON DELETE CASCADE,
  CONSTRAINT ev_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES users(userID) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;