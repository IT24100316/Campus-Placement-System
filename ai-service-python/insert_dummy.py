import psycopg2
import uuid
import datetime

conn_str = "host='db.hyxtmbncjolcepfvongh.supabase.co' port='5432' dbname='postgres' user='postgres' password='Sef@project#123' sslmode='require'"

try:
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()

    # Insert dummy user (student)
    student_id = str(uuid.uuid4())
    cur.execute("""
        INSERT INTO "Users" ("Id", "Email", "PasswordHash", "Role", "Status", "CreatedAt")
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (student_id, 'dummy.student@example.com', 'hash', 'Student', 'Approved', datetime.datetime.now()))
    
    # Insert dummy student profile
    cur.execute("""
        INSERT INTO "StudentProfiles" ("UserId", "FullName", "UniversityName", "CvPdfUrl", "DegreeProgram", "GPA", "ExpectedGraduationDate", "AcademicStatus", "PrimaryDomain", "Phone", "CampusIdPhotoUrl", "CurrentYearOfStudy", "DesiredJobTitle", "CareerObjectivesSummary", "Skills", "ToolsAndTechnologies", "PreferredLocations", "InternshipType", "LectureScheduleType")
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ARRAY['Python']::text[], ARRAY['Git']::text[], ARRAY['Remote']::text[], ARRAY['Full-Time']::text[], ARRAY['Morning']::text[])
    """, (student_id, 'Dummy Student', 'SLIIT', 'local://dummy.pdf', 'BSc SE', 3.5, datetime.datetime.now(), 'Active', 'SE', '1234567890', 'local://dummy.jpg', 3, 'Software Engineer', 'Dummy objectives'))

    # Get a job or create one
    cur.execute("SELECT \"JobId\" FROM \"Jobs\" LIMIT 1")
    job = cur.fetchone()
    if job:
        job_id = job[0]
    else:
        # We need a company user first
        company_id = str(uuid.uuid4())
        cur.execute("""
            INSERT INTO "Users" ("Id", "Email", "PasswordHash", "Role", "Status", "CreatedAt")
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (company_id, 'dummy.company@example.com', 'hash', 'Company', 'Approved', datetime.datetime.now()))
        job_id = str(uuid.uuid4())
        cur.execute("""
            INSERT INTO "Jobs" ("JobId", "CompanyId", "JobTitle", "TargetDomain", "JobDescriptionSummary", "MinimumGPA", "StipendOffered", "DurationMonths", "ApplicationDeadline", "CreatedAt")
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (job_id, company_id, 'Dummy Job', 'SE', 'Dummy desc', 3.0, True, 6, datetime.datetime.now(), datetime.datetime.now()))

    app_id = str(uuid.uuid4())
    
    # Insert Pending Application
    cur.execute("""
        INSERT INTO "Applications" ("AppId", "StudentId", "JobId", "Status", "SummaryReport", "MatchScore")
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (app_id, student_id, job_id, 'Pending', '{}', 0))
    
    conn.commit()
    print(f"Successfully created Dummy Student, Job, and Pending Application: {app_id}")

except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals():
        conn.close()
