#!/bin/bash

# Function to create the SQLite database and its tables
create_database() {
	DB_FILE=$1
	sqlite3 "$DB_FILE" <<EOF
		CREATE TABLE IF NOT EXISTS status_help (
			status_value INTEGER PRIMARY KEY,
			status TEXT
		);

		INSERT OR IGNORE INTO status_help (status_value, status) 
		VALUES 
			(0, 'extracted'),
			(1, 'downloaded'),
			(2, 'visiting error'),
			(3, 'only visited, downloading error try 1'),
			(4, 'only visited, downloading error try 2'),
			(5, 'only visited, downloading error try 3'),
			(6, 'error: downloading attempt exceeded');

		CREATE TABLE IF NOT EXISTS links (
		    id INTEGER PRIMARY KEY AUTOINCREMENT,  -- Auto-incrementing id, unique and primary key
		    raw_link TEXT UNIQUE,                  -- raw_link must be unique
		    original_link TEXT UNIQUE,             -- original_link must be unique
		    updated_link TEXT UNIQUE,              -- updated_link must be unique
		    status INTEGER,
		    FOREIGN KEY (status) REFERENCES status_help(status_value)
		);


EOF
}
