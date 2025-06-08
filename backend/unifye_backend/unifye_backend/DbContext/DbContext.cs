using Microsoft.EntityFrameworkCore;
using unifye_backend.Models;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
    : base(options) { }

    public DbSet<Profile> Profiles { get; set; }
}



