namespace backend_dotnet.Models;

public enum UserRole
{
    Student,
    Company,
    Admin
}

public enum AccountStatus
{
    Pending,
    Approved,
    Rejected,
    Suspended
}

public enum ApplicationStatus
{
    Pending,
    Rejected,
    Agent_Evaluated,
    Admin_Approved,
    Company_Scheduled,
    Student_Accepted,
    Processing,
    Evaluation_Failed
}
