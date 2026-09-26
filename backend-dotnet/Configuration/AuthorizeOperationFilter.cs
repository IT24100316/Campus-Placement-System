using Microsoft.AspNetCore.Authorization;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace backend_dotnet.Configuration;

public sealed class AuthorizeOperationFilter : IOperationFilter
{
    public void Apply(OpenApiOperation operation, OperationFilterContext context)
    {
        var action = context.MethodInfo;
        var controller = action.DeclaringType;
        if (action.IsDefined(typeof(AllowAnonymousAttribute), inherit: true) ||
            controller?.IsDefined(typeof(AllowAnonymousAttribute), inherit: true) == true)
        {
            return;
        }

        if (!action.IsDefined(typeof(AuthorizeAttribute), inherit: true) &&
            controller?.IsDefined(typeof(AuthorizeAttribute), inherit: true) != true)
        {
            return;
        }

        operation.Security ??= new List<OpenApiSecurityRequirement>();
        operation.Security.Add(new OpenApiSecurityRequirement
        {
            [new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            }] = Array.Empty<string>()
        });
    }
}
