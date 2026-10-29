-- Migration: Add peer review tables for Phase 2
-- Date: 2026-09-14

-- Peer review rubrics: stores rubric definitions
CREATE TABLE IF NOT EXISTS peer_review_rubrics (
  rubric_id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  criteria JSON NOT NULL COMMENT 'JSON array of {name, description, weight}',
  created_by INT NULL COMMENT 'users.userID',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (rubric_id),
  CONSTRAINT pr_rubric_created_by FOREIGN KEY (created_by) REFERENCES users(userID) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Per-assignment peer review configuration
CREATE TABLE IF NOT EXISTS peer_review_configs (
  config_id INT NOT NULL AUTO_INCREMENT,
  assignment_id INT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT FALSE,
  num_peers INT NOT NULL DEFAULT 2 COMMENT 'Number of peers each student must review (1-5)',
  deadline DATETIME NULL COMMENT 'Peer review deadline; must be after assignment due date',
  rubric_id INT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (config_id),
  UNIQUE KEY uniq_pr_config_assignment (assignment_id),
  CONSTRAINT pr_config_assignment FOREIGN KEY (assignment_id) REFERENCES assignment(assignmentID) ON DELETE CASCADE,
  CONSTRAINT pr_config_rubric FOREIGN KEY (rubric_id) REFERENCES peer_review_rubrics(rubric_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Peer assignment mappings: reviewer -> reviewee submission
CREATE TABLE IF NOT EXISTS peer_review_assignments (
  id INT NOT NULL AUTO_INCREMENT,
  assignment_id INT NOT NULL,
  reviewer_user_id INT NOT NULL,
  reviewee_submission_id INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uniq_pr_assignment (assignment_id, reviewer_user_id, reviewee_submission_id),
  KEY idx_pr_reviewer (reviewer_user_id),
  CONSTRAINT pr_assign_assignment FOREIGN KEY (assignment_id) REFERENCES assignment(assignmentID) ON DELETE CASCADE,
  CONSTRAINT pr_assign_reviewer FOREIGN KEY (reviewer_user_id) REFERENCES users(userID) ON DELETE CASCADE,
  CONSTRAINT pr_assign_reviewee_sub FOREIGN KEY (reviewee_submission_id) REFERENCES submission(submissionID) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Completed peer reviews
CREATE TABLE IF NOT EXISTS peer_review_submissions (
  id INT NOT NULL AUTO_INCREMENT,
  assignment_id INT NOT NULL,
  reviewer_id INT NOT NULL,
  reviewee_id INT NOT NULL,
  reviewee_submission_id INT NOT NULL,
  rubric_scores JSON NULL COMMENT 'JSON array of {criteria_name, score}',
  comments TEXT NULL,
  override_score DECIMAL(5,2) NULL COMMENT 'Lecturer override; original score retained in rubric_scores',
  override_comment VARCHAR(2000) NULL,
  submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uniq_pr_submission (assignment_id, reviewer_id, reviewee_submission_id),
  CONSTRAINT pr_sub_assignment FOREIGN KEY (assignment_id) REFERENCES assignment(assignmentID) ON DELETE CASCADE,
  CONSTRAINT pr_sub_reviewer FOREIGN KEY (reviewer_id) REFERENCES users(userID) ON DELETE CASCADE,
  CONSTRAINT pr_sub_reviewee FOREIGN KEY (reviewee_id) REFERENCES users(userID) ON DELETE CASCADE,
  CONSTRAINT pr_sub_reviewee_sub FOREIGN KEY (reviewee_submission_id) REFERENCES submission(submissionID) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;