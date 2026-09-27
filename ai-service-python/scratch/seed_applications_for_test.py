import psycopg2
import uuid
import json
from datetime import datetime, timedelta, timezone

def seed_data():
    conn = psycopg2.connect(
        host='db.hyxtmbncjolcepfvongh.supabase.co',
        port=5432,
        dbname='postgres',
        user='postgres',
        password='Sef@project#123',
        sslmode='require'
    )
    cur = conn.cursor()

    try:
        # 1. Get test student ID
        cur.execute("SELECT \"Id\" FROM \"Users\" WHERE \"Email\" = 'test@student.com';")
        student_row = cur.fetchone()
        if not student_row:
            print("Error: test@student.com not found!")
            return
        student_id = student_row[0]
        print(f"Found Student ID: {student_id}")

        # 2. Get any valid Company ID to link jobs to
        cur.execute("SELECT \"UserId\" FROM \"CompanyProfiles\" LIMIT 1;")
        company_row = cur.fetchone()
        if not company_row:
            print("Error: No companies found in the database!")
            return
        company_id = company_row[0]
        print(f"Using Company ID: {company_id}")

        # 3. Create dummy jobs
        job_data = [
            ("OmniCore Analytics", "Data Analyst Fellow"),
            ("TechFlow", "Senior Frontend Engineer"),
            ("CyberShield", "Security Analyst"),
            ("CloudScale", "DevOps Engineer"),
            ("DataMinds", "Machine Learning Intern"),
            ("FinTrust Global", "Backend Developer"),
            ("Vanguard Robotics", "Frontend Engineer"),
            ("Horizon Quantum", "Systems Architecture Fellow"),
            ("DeepMind Labs", "ML Research Intern"),
            ("Apex Quantitative", "Quant Developer Co-op")
        ]

        # Applications data mapping to statuses (integers)
        # Pending=0, Rejected=1, Agent_Evaluated=2, Admin_Approved=3, Company_Scheduled=4, Student_Accepted=5
        statuses = [
            3, 3, 4, 4, 3, # 5 Action Req (Admin_Approved, Company_Scheduled)
            0, 2, 2, # 3 Pending (Pending, Agent_Evaluated)
            5, 1 # 2 History (Student_Accepted, Rejected)
        ]

        print("Inserting Jobs and Applications...")
        for i in range(10):
            job_id = str(uuid.uuid4())
            company_name, job_title = job_data[i]
            status = statuses[i]
            
            # Insert Job
            cur.execute("""
                INSERT INTO "Jobs" (
                    "JobId", "CompanyId", "JobTitle", "TargetDomain", "InternshipType", 
                    "LocationCity", "JobDescriptionSummary", "MandatorySkills", 
                    "NiceToHaveSkills", "MinimumGPA", "AllowedYearsOfStudy", 
                    "PreferredDegreePrograms", "StipendOffered", "StipendAmountOrDetails", 
                    "DurationMonths", "ApplicationDeadline", "CreatedAt"
                ) VALUES (
                    %s, %s, %s, %s, ARRAY['Full-Time'], %s, %s, ARRAY['Python'], 
                    ARRAY['AWS'], 3.0, ARRAY[3], ARRAY['Software Engineering'], 
                    true, '21.5 LPA', 6, %s, %s
                )
            """, (
                job_id, company_id, job_title, 'Software Engineering', 'Colombo', 
                f'Description for {job_title}', 
                datetime.now(timezone.utc) + timedelta(days=30), 
                datetime.now(timezone.utc)
            ))

            # Insert Application
            app_id = str(uuid.uuid4())
            cur.execute("""
                INSERT INTO "Applications" (
                    "AppId", "StudentId", "JobId", "Status", "MatchScore", 
                    "SummaryReport"
                ) VALUES (
                    %s, %s, %s, %s, %s, %s
                )
            """, (
                app_id, student_id, job_id, status, 90 - i, 
                json.dumps({"summary": f"Generated summary for {job_title}"})
            ))

        conn.commit()
        print("Successfully seeded 10 applications!")

    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()

if __name__ == '__main__':
    seed_data()
