using Microsoft.EntityFrameworkCore;
using Unifye.Models;

namespace Unifye.Data;

public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();

    public DbSet<UserProfile> UserProfiles => Set<UserProfile>();

    public DbSet<UserInterest> UserInterests => Set<UserInterest>();

    public DbSet<UserSwipe> UserSwipes => Set<UserSwipe>();

    public DbSet<UserMatch> UserMatches => Set<UserMatch>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.HasDefaultSchema("development");

        modelBuilder.Entity<User>()
            .ToTable("users")
            .HasIndex(user => user.Email)
            .IsUnique();

        modelBuilder.Entity<User>()
            .Property(user => user.Email)
            .HasConversion(email => email.ToLowerInvariant(), email => email);

        modelBuilder.Entity<User>()
            .HasOne(user => user.Profile)
            .WithOne(profile => profile.User)
            .HasForeignKey<UserProfile>(profile => profile.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserProfile>()
            .ToTable("user_profiles")
            .HasMany(profile => profile.Interests)
            .WithOne(interest => interest.UserProfile)
            .HasForeignKey(interest => interest.UserProfileId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserInterest>()
            .ToTable("user_interests");

        modelBuilder.Entity<User>()
            .Navigation(user => user.Profile)
            .AutoInclude();

        modelBuilder.Entity<UserSwipe>()
            .ToTable("user_swipes")
            .HasIndex(swipe => new { swipe.SourceUserId, swipe.TargetUserId })
            .IsUnique();

        modelBuilder.Entity<UserMatch>()
            .ToTable("user_matches")
            .HasIndex(match => new { match.UserOneId, match.UserTwoId })
            .IsUnique();
    }
}
