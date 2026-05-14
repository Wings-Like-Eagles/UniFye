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
    public DbSet<SubscriptionPlan> SubscriptionPlans => Set<SubscriptionPlan>();
    public DbSet<PlanFeaturePermissions> PlanFeaturePermissions => Set<PlanFeaturePermissions>();
    public DbSet<UserSubscription> UserSubscriptions => Set<UserSubscription>();
    public DbSet<SubscriptionHistory> SubscriptionHistories => Set<SubscriptionHistory>();
    public DbSet<ProcessedStripeEvent> ProcessedStripeEvents => Set<ProcessedStripeEvent>();
    public DbSet<Message> Messages => Set<Message>();
    public DbSet<Conversation> Conversations => Set<Conversation>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.HasDefaultSchema("development");

        modelBuilder.Entity<User>()
            .ToTable("users")
            .HasIndex(u => u.Email)
            .IsUnique();

        modelBuilder.Entity<User>()
            .Property(u => u.Email)
            .HasConversion(e => e.ToLowerInvariant(), e => e);

        modelBuilder.Entity<User>()
            .HasOne(u => u.Profile)
            .WithOne(p => p.User)
            .HasForeignKey<UserProfile>(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserProfile>()
            .ToTable("user_profiles")
            .HasMany(p => p.Interests)
            .WithOne(i => i.UserProfile)
            .HasForeignKey(i => i.UserProfileId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserInterest>()
            .ToTable("user_interests");

        modelBuilder.Entity<User>()
            .Navigation(u => u.Profile)
            .AutoInclude();

        modelBuilder.Entity<UserSwipe>()
            .ToTable("user_swipes")
            .HasIndex(s => new { s.SourceUserId, s.TargetUserId })
            .IsUnique();

        modelBuilder.Entity<UserMatch>()
            .ToTable("user_matches")
            .HasIndex(m => new { m.UserOneId, m.UserTwoId })
            .IsUnique();

        // ─── Subscription Plans ───────────────────────────────────────────────

        modelBuilder.Entity<SubscriptionPlan>()
            .ToTable("subscription_plans")
            .HasOne(p => p.Permissions)
            .WithOne(p => p.Plan)
            .HasForeignKey<PlanFeaturePermissions>(p => p.PlanId) // ← PlanId
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<PlanFeaturePermissions>()
            .ToTable("plan_feature_permissions");

        // ─── User Subscriptions ───────────────────────────────────────────────

        modelBuilder.Entity<UserSubscription>()
            .ToTable("user_subscriptions")
            .HasIndex(s => s.UserId)
            .IsUnique();

        modelBuilder.Entity<UserSubscription>()
            .HasIndex(s => s.StripeCustomerId)
            .IsUnique();

        // ─── Subscription History ─────────────────────────────────────────────

        modelBuilder.Entity<SubscriptionHistory>()
            .ToTable("subscription_history")
            .Property(h => h.Metadata)
            .HasColumnType("jsonb");

        // ─── Stripe Event Idempotency ─────────────────────────────────────────

        modelBuilder.Entity<ProcessedStripeEvent>()
            .ToTable("processed_stripe_events")
            .HasIndex(e => e.StripeEventId)
            .IsUnique();

        // ─── Message and Conversation ─────────────────────────────────────────

        modelBuilder.Entity<Message>(entity =>
        {
            entity.ToTable("messages");

            entity.HasKey(x => x.Id);

            entity.Property(x => x.Content)
                .IsRequired()
                .HasMaxLength(4000);

            entity.HasOne(x => x.Sender)
                .WithMany()
                .HasForeignKey(x => x.SenderId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(x => x.Receiver)
                .WithMany()
                .HasForeignKey(x => x.ReceiverId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Conversation>(entity =>
        {
            entity.ToTable("conversations");

            entity.HasKey(x => x.Id);

            entity.HasIndex(x => new
            {
                x.UserOneId,
                x.UserTwoId
            }).IsUnique();
        });
    }
}
