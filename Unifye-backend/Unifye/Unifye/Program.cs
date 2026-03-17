using Microsoft.EntityFrameworkCore;
using Unifye.Data;
using Unifye.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ISwipeService, SwipeService>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy
            .AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();
app.UseCors("AllowFrontend");
app.UseStaticFiles();
app.UseAuthorization();

app.MapControllers();

using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    dbContext.Database.EnsureCreated();
    dbContext.Database.ExecuteSqlRaw("""
        CREATE TABLE IF NOT EXISTS UserSwipes (
            Id INTEGER PRIMARY KEY AUTOINCREMENT,
            SourceUserId TEXT NOT NULL,
            TargetUserId TEXT NOT NULL,
            IsLiked INTEGER NOT NULL,
            CreatedAtUtc TEXT NOT NULL
        );
        """);
    dbContext.Database.ExecuteSqlRaw("""
        CREATE UNIQUE INDEX IF NOT EXISTS IX_UserSwipes_SourceUserId_TargetUserId
        ON UserSwipes(SourceUserId, TargetUserId);
        """);
    dbContext.Database.ExecuteSqlRaw("""
        CREATE TABLE IF NOT EXISTS UserMatches (
            Id INTEGER PRIMARY KEY AUTOINCREMENT,
            UserOneId TEXT NOT NULL,
            UserTwoId TEXT NOT NULL,
            CreatedAtUtc TEXT NOT NULL
        );
        """);
    dbContext.Database.ExecuteSqlRaw("""
        CREATE UNIQUE INDEX IF NOT EXISTS IX_UserMatches_UserOneId_UserTwoId
        ON UserMatches(UserOneId, UserTwoId);
        """);
}

app.Run();
