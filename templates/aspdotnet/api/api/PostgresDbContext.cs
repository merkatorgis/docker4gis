using Microsoft.EntityFrameworkCore;

public class PostgresDbContext : DbContext
{
    public PostgresDbContext(
        DbContextOptions<PostgresDbContext> dbContextOptionsBuilder
    ) : base(dbContextOptionsBuilder)
    {
    }

    public static string ConnectionString(ConfigurationManager conf)
    {
        string connectionString = ""
            + $"Host={conf["PGHOSTADDR"]}"
            + $";Port={conf["PGPORT"]}"
            + $";Database={conf["PGDATABASE"]}"
            + $";Username={conf["PGUSER"]}"
            + $";Password={conf["PGPASSWORD"]}";
        return connectionString;
    }

}
