namespace backend_dotnet.Configuration;

public sealed class CvStorageOptions
{
    public const string SectionName = "CvStorage";
    public const long DefaultMaxFileSizeBytes = 10 * 1024 * 1024;

    /// <summary>
    /// Absolute path to a directory outside the source-controlled workspace.
    /// Configure with CvStorage__RootPath.
    /// </summary>
    public string RootPath { get; set; } = string.Empty;

    /// <summary>
    /// Maximum allowed CV upload size. Defaults to 10 MB.
    /// Configure with CvStorage__MaxFileSizeBytes.
    /// </summary>
    public long MaxFileSizeBytes { get; set; } = DefaultMaxFileSizeBytes;
}
