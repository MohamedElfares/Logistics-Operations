"""
run_pipeline.py
===============
Automates the full logistics database setup pipeline by executing
the four SQL scripts in sequence:

    01_connect.sql       → Drop/create schema, enable local infile
    02_schema.sql        → Tables, triggers, procedures, functions
    03_optimization.sql  → Analytical views and performance indexes
    04_load_data.sql     → Load all CSV datasets into the database

Requirements:
    pip install mysql-connector-python

Usage:
    python run_pipeline.py

Configuration:
    Edit the CONFIG and SCRIPTS sections below before running.
"""

import mysql.connector
import os
import sys
import time


# ============================================================
# CONFIGURATION
# Edit these values to match your environment.
# ============================================================
CONFIG = {
    "host":             "localhost",
    "user":             "root",
    "password":         "",          # Your MySQL root password
    "allow_local_infile": True,      # Required for LOAD DATA LOCAL INFILE
}

# Absolute or relative paths to the SQL script files.
# Order matters — do not change the sequence.
SCRIPTS = [
    "connect.sql",
    "schema.sql",
    "optimization.sql",
    "load_data.sql",
]


# ============================================================
# HELPER FUNCTIONS
# ============================================================

def log(message: str, level: str = "INFO") -> None:
    """Prints a timestamped log message to stdout."""
    timestamp = time.strftime("%H:%M:%S")
    print(f"[{timestamp}] [{level}] {message}")


def read_script(filepath: str) -> str:
    """Reads and returns the content of a SQL file."""
    if not os.path.isfile(filepath):
        raise FileNotFoundError(f"SQL file not found: {filepath}")
    with open(filepath, "r", encoding="utf-8") as f:
        return f.read()


def split_statements(sql: str) -> list[str]:
    """
    Splits a SQL script into individual executable statements,
    handling DELIMITER changes used in stored procedures and triggers.

    Standard MySQL clients support DELIMITER directives natively,
    but the Python connector does not — this function emulates that
    behavior by detecting delimiter changes and splitting accordingly.
    """
    statements = []
    current_delimiter = ";"
    buffer = []

    for line in sql.splitlines():
        stripped = line.strip()

        # Detect DELIMITER directive (e.g. "DELIMITER //")
        if stripped.upper().startswith("DELIMITER"):
            parts = stripped.split()
            if len(parts) == 2:
                # If switching back to semicolon, flush buffer first
                if parts[1] == ";":
                    current_delimiter = ";"
                else:
                    current_delimiter = parts[1]
            continue  # DELIMITER lines are not SQL — skip them

        buffer.append(line)
        joined = "\n".join(buffer)

        # Check if buffer ends with the current delimiter
        if joined.rstrip().endswith(current_delimiter):
            # Strip the trailing delimiter before executing
            stmt = joined.rstrip()
            if current_delimiter != ";":
                stmt = stmt[: -len(current_delimiter)]
            stmt = stmt.strip()
            if stmt:
                statements.append(stmt)
            buffer = []

    # Flush any remaining content
    remaining = "\n".join(buffer).strip()
    if remaining:
        statements.append(remaining)

    return statements


def execute_script(cursor, filepath: str) -> None:
    """Reads a SQL file and executes all statements within it."""
    log(f"Reading: {filepath}")
    sql = read_script(filepath)
    statements = split_statements(sql)

    executed = 0
    for stmt in statements:
        if not stmt.strip():
            continue
        try:
            cursor.execute(stmt)
            executed += 1
        except mysql.connector.Error as err:
            log(f"Error in statement:\n{stmt[:120]}...", level="ERROR")
            raise err

    log(f"Completed: {filepath} — {executed} statement(s) executed.")


# ============================================================
# MAIN PIPELINE
# ============================================================

def main() -> None:
    log("Starting logistics database pipeline.")
    start_time = time.time()

    # Establish connection
    log("Connecting to MySQL server...")
    try:
        conn = mysql.connector.connect(**CONFIG)
    except mysql.connector.Error as err:
        log(f"Connection failed: {err}", level="ERROR")
        sys.exit(1)

    log("Connection established.")
    cursor = conn.cursor()

    # Execute each script in order
    for script in SCRIPTS:
        log(f"--- Running {script} ---")
        try:
            execute_script(cursor, script)
            conn.commit()
        except mysql.connector.Error as err:
            log(f"Pipeline failed on {script}: {err}", level="ERROR")
            conn.rollback()
            cursor.close()
            conn.close()
            sys.exit(1)

    # Cleanup
    cursor.close()
    conn.close()

    elapsed = round(time.time() - start_time, 2)
    log(f"Pipeline completed successfully in {elapsed}s.")


if __name__ == "__main__":
    main()
