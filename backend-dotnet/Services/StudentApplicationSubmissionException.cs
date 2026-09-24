namespace backend_dotnet.Services;

public enum StudentApplicationSubmissionError
{
    Unauthorized,
    Forbidden,
    JobNotFound,
    InvalidProfile,
    ExpiredJob,
    Duplicate
}

public sealed class StudentApplicationSubmissionException : Exception
{
    public StudentApplicationSubmissionException(StudentApplicationSubmissionError error, string message)
        : base(message)
    {
        Error = error;
    }

    public StudentApplicationSubmissionError Error { get; }
}
