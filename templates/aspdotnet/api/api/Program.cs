using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure a Microsoft.EntityFrameworkCore.DbContext connecting to the
// PostgreSQL database container.
builder.Services.AddDbContext<PostgresDbContext>(dbContextOptionsBuilder =>
{
    string connectionString = PostgresDbContext.ConnectionString(
        builder.Configuration);
    dbContextOptionsBuilder.UseNpgsql(connectionString);
});

var app = builder.Build();

// Following Microsoft's Configure ASP.NET Core to work with proxy servers and
// load balancers;
// https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/proxy-load-balancer?view=aspnetcore-8.0..
var fordwardedHeaderOptions = new ForwardedHeadersOptions
{
    ForwardedHeaders = Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.All,
    RequireHeaderSymmetry = false,
};
fordwardedHeaderOptions.KnownNetworks.Clear();
fordwardedHeaderOptions.KnownProxies.Clear();
app.UseForwardedHeaders(fordwardedHeaderOptions);

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

Endpoints.Map(app);

app.Run();
