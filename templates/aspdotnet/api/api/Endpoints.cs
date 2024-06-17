using Microsoft.EntityFrameworkCore;

public class Endpoints
{

    public static void Map(WebApplication app)
    {
        app.MapGet("/", () =>
        {
            return "Honey, I'm home!";
        })
        .WithOpenApi();

        app.MapGet("/db", (PostgresDbContext db) =>
        {
            string sql = @$"select 'PostgreSQL text'";
            string? text = db.Database.SqlQueryRaw<string?>(sql).ToArray()[0];
            return text;
        })
        .WithOpenApi();
    }
}
