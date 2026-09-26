using System.Net.Http.Headers;
using System.Text.Json;

namespace backend_dotnet.Services;

internal static class SupabaseStorageAuthentication
{
    public static bool IsPrivilegedKey(string? key)
    {
        if (string.IsNullOrWhiteSpace(key)) return false;
        if (key.StartsWith("sb_secret_", StringComparison.Ordinal))
            return key.Length > "sb_secret_".Length;

        if (!key.StartsWith("eyJ", StringComparison.Ordinal)) return false;
        var segments = key.Split('.');
        if (segments.Length != 3 || segments.Any(string.IsNullOrWhiteSpace)) return false;

        try
        {
            var payload = segments[1].Replace('-', '+').Replace('_', '/');
            payload = payload.PadRight((payload.Length + 3) / 4 * 4, '=');
            using var document = JsonDocument.Parse(Convert.FromBase64String(payload));
            return document.RootElement.TryGetProperty("role", out var role)
                && role.ValueKind == JsonValueKind.String
                && role.GetString() == "service_role";
        }
        catch (Exception exception) when (exception is FormatException or JsonException)
        {
            return false;
        }
    }

    public static void AddHeaders(HttpRequestMessage request, string key)
    {
        if (!IsPrivilegedKey(key))
            throw new InvalidOperationException("A privileged Supabase storage key is required.");

        request.Headers.TryAddWithoutValidation("apikey", key);
        if (key.StartsWith("eyJ", StringComparison.Ordinal))
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", key);
    }
}
