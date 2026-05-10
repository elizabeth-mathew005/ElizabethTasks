-- Zen Class Programme Database Design
-- This database manages users, coding challenges, attendance, topics, tasks, company drives, and mentors

CREATE DATABASE IF NOT EXISTS zen_class;
USE zen_class;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    date_of_join DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Topics table
CREATE TABLE IF NOT EXISTS topics (
    topic_id INT AUTO_INCREMENT PRIMARY KEY,
    topic_name VARCHAR(150) NOT NULL,
    description TEXT,
    month INT,
    year INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    task_id INT AUTO_INCREMENT PRIMARY KEY,
    task_name VARCHAR(150) NOT NULL,
    description TEXT,
    assignment_date DATE NOT NULL,
    due_date DATE NOT NULL,
    month INT,
    year INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Attendance table
CREATE TABLE IF NOT EXISTS attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    attendance_date DATE NOT NULL,
    is_present BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    UNIQUE KEY unique_attendance (user_id, attendance_date)
);

-- CodeKata table (Coding challenges/problems)
CREATE TABLE IF NOT EXISTS codekata (
    codekata_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    problem_id INT NOT NULL,
    problem_name VARCHAR(150) NOT NULL,
    solved_date DATE,
    is_solved BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Company Drives table
CREATE TABLE IF NOT EXISTS company_drives (
    drive_id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(150) NOT NULL,
    drive_date DATE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Placement (Company Drives and Students) junction table
CREATE TABLE IF NOT EXISTS drive_placements (
    placement_id INT AUTO_INCREMENT PRIMARY KEY,
    drive_id INT NOT NULL,
    user_id INT NOT NULL,
    appeared BOOLEAN DEFAULT FALSE,
    selected BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (drive_id) REFERENCES company_drives(drive_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Mentors table
CREATE TABLE IF NOT EXISTS mentors (
    mentor_id INT AUTO_INCREMENT PRIMARY KEY,
    mentor_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    specialization VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Mentor-Mentee relationship table
CREATE TABLE IF NOT EXISTS mentee_mapping (
    mapping_id INT AUTO_INCREMENT PRIMARY KEY,
    mentor_id INT NOT NULL,
    user_id INT NOT NULL,
    assigned_date DATE NOT NULL,
    FOREIGN KEY (mentor_id) REFERENCES mentors(mentor_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Task Submissions table
CREATE TABLE IF NOT EXISTS task_submissions (
    submission_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    task_id INT NOT NULL,
    submission_date DATE,
    is_submitted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (task_id) REFERENCES tasks(task_id)
);

-- ============================================
-- QUERIES FOR REQUIREMENTS
-- ============================================

-- 1. Find all the topics and tasks which are taught in the month of October
SELECT 
    t.topic_id,
    t.topic_name,
    t.month,
    t.year
FROM topics t
WHERE t.month = 10
UNION
SELECT 
    NULL,
    ts.task_name,
    ts.month,
    ts.year
FROM tasks ts
WHERE ts.month = 10
ORDER BY year DESC, topic_name;

-- 2. Find all the company drives which appeared between 15-oct-2020 and 31-oct-2020
SELECT 
    cd.drive_id,
    cd.company_name,
    cd.drive_date,
    cd.description
FROM company_drives cd
WHERE cd.drive_date BETWEEN '2020-10-15' AND '2020-10-31'
ORDER BY cd.drive_date;

-- 3. Find all the company drives and students who appeared for the placement
SELECT 
    cd.drive_id,
    cd.company_name,
    cd.drive_date,
    u.user_id,
    u.user_name,
    u.email,
    dp.appeared,
    dp.selected
FROM company_drives cd
JOIN drive_placements dp ON cd.drive_id = dp.drive_id
JOIN users u ON dp.user_id = u.user_id
WHERE dp.appeared = TRUE
ORDER BY cd.drive_date, u.user_name;

-- 4. Find the number of problems solved by the user in CodeKata
SELECT 
    u.user_id,
    u.user_name,
    COUNT(CASE WHEN ck.is_solved = TRUE THEN 1 END) AS problems_solved
FROM users u
LEFT JOIN codekata ck ON u.user_id = ck.user_id
GROUP BY u.user_id, u.user_name
ORDER BY problems_solved DESC;

-- 5. Find all the mentors who have mentee count more than 15
SELECT 
    m.mentor_id,
    m.mentor_name,
    m.email,
    m.specialization,
    COUNT(mm.user_id) AS mentee_count
FROM mentors m
LEFT JOIN mentee_mapping mm ON m.mentor_id = mm.mentor_id
GROUP BY m.mentor_id, m.mentor_name, m.email, m.specialization
HAVING COUNT(mm.user_id) > 15
ORDER BY mentee_count DESC;


-- 6. Find the number of users who are absent and task is not submitted between 15-oct-2020 and 31-oct-2020
SELECT 
    u.user_id,
    u.user_name,
    u.email,
    COUNT(DISTINCT CASE WHEN a.is_present = FALSE AND a.attendance_date BETWEEN '2020-10-15' AND '2020-10-31' THEN a.attendance_date END) AS absent_days,
    COUNT(DISTINCT CASE WHEN ts.is_submitted = FALSE AND ts.submission_date BETWEEN '2020-10-15' AND '2020-10-31' THEN ts.task_id END) AS unsubmitted_tasks
FROM users u
LEFT JOIN attendance a ON u.user_id = a.user_id
LEFT JOIN task_submissions ts ON u.user_id = ts.user_id
WHERE (a.is_present = FALSE AND a.attendance_date BETWEEN '2020-10-15' AND '2020-10-31')
   OR (ts.is_submitted = FALSE AND ts.submission_date BETWEEN '2020-10-15' AND '2020-10-31')
GROUP BY u.user_id, u.user_name, u.email
ORDER BY absent_days DESC, unsubmitted_tasks DESC;
