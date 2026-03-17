using Microsoft.EntityFrameworkCore;
using Unifye.Models;

namespace Unifye.Data;

public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();

    public DbSet<UserInterest> UserInterests => Set<UserInterest>();

    public DbSet<UserSwipe> UserSwipes => Set<UserSwipe>();

    public DbSet<UserMatch> UserMatches => Set<UserMatch>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<User>()
            .HasIndex(user => user.Email)
            .IsUnique();

        modelBuilder.Entity<User>()
            .Property(user => user.Email)
            .HasConversion(email => email.ToLowerInvariant(), email => email);

        modelBuilder.Entity<User>()
            .HasMany(user => user.Interests)
            .WithOne(interest => interest.User)
            .HasForeignKey(interest => interest.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserSwipe>()
            .HasIndex(swipe => new { swipe.SourceUserId, swipe.TargetUserId })
            .IsUnique();

        modelBuilder.Entity<UserMatch>()
            .HasIndex(match => new { match.UserOneId, match.UserTwoId })
            .IsUnique();
    }
}
