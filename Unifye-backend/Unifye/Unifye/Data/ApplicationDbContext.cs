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

    // ─── Events ──────────────────────────────────────────────────────────────

    public DbSet<Event> Events => Set<Event>();
    public DbSet<EventAttendee> EventAttendees => Set<EventAttendee>();
    public DbSet<EventChatMessage> EventChatMessages => Set<EventChatMessage>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.HasDefaultSchema("development");

        // ─── Users ────────────────────────────────────────────────────────────

        modelBuilder.Entity<User>()
            .ToTable("users")
            .HasIndex(u => u.Email)
            .IsUnique();

        modelBuilder.Entity<User>()
            .Property(u => u.Email)
            .HasConversion(
                e => e.ToLowerInvariant(),
                e => e);

        modelBuilder.Entity<User>()
            .HasOne(u => u.Profile)
            .WithOne(p => p.User)
            .HasForeignKey<UserProfile>(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<User>()
            .Navigation(u => u.Profile)
            .AutoInclude();

        // ─── User Profiles ───────────────────────────────────────────────────

        modelBuilder.Entity<UserProfile>()
            .ToTable("user_profiles")
            .HasMany(p => p.Interests)
            .WithOne(i => i.UserProfile)
            .HasForeignKey(i => i.UserProfileId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserInterest>()
            .ToTable("user_interests");

        // ─── Swipes & Matches ────────────────────────────────────────────────

        modelBuilder.Entity<UserSwipe>()
            .ToTable("user_swipes")
            .HasIndex(s => new
            {
                s.SourceUserId,
                s.TargetUserId
            })
            .IsUnique();

        modelBuilder.Entity<UserMatch>()
            .ToTable("user_matches")
            .HasIndex(m => new
            {
                m.UserOneId,
                m.UserTwoId
            })
            .IsUnique();

        // ─── Subscription Plans ──────────────────────────────────────────────

        modelBuilder.Entity<SubscriptionPlan>()
            .ToTable("subscription_plans")
            .HasOne(p => p.Permissions)
            .WithOne(p => p.Plan)
            .HasForeignKey<PlanFeaturePermissions>(p => p.PlanId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<PlanFeaturePermissions>()
            .ToTable("plan_feature_permissions");

        // ─── User Subscriptions ──────────────────────────────────────────────

        modelBuilder.Entity<UserSubscription>()
            .ToTable("user_subscriptions")
            .HasIndex(s => s.UserId)
            .IsUnique();

        modelBuilder.Entity<UserSubscription>()
            .HasIndex(s => s.StripeCustomerId)
            .IsUnique();

        // ─── Subscription History ────────────────────────────────────────────

        modelBuilder.Entity<SubscriptionHistory>()
            .ToTable("subscription_history");

        modelBuilder.Entity<SubscriptionHistory>()
            .Property(h => h.Metadata)
            .HasColumnType("jsonb");

        // ─── Stripe Events ───────────────────────────────────────────────────

        modelBuilder.Entity<ProcessedStripeEvent>()
            .ToTable("processed_stripe_events")
            .HasIndex(e => e.StripeEventId)
            .IsUnique();

        // ─── Conversations ───────────────────────────────────────────────────

        modelBuilder.Entity<Conversation>(entity =>
        {
            entity.ToTable("conversations");

            entity.HasKey(x => x.Id);

            entity.HasIndex(x => new
            {
                x.UserOneId,
                x.UserTwoId
            }).IsUnique();

            entity.HasOne(x => x.UserOne)
                .WithMany()
                .HasForeignKey(x => x.UserOneId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(x => x.UserTwo)
                .WithMany()
                .HasForeignKey(x => x.UserTwoId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // ─── Messages ────────────────────────────────────────────────────────

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

        // ─── Events ──────────────────────────────────────────────────────────

        modelBuilder.Entity<Event>(entity =>
        {
            entity.ToTable("events");

            entity.HasKey(e => e.Id);

            entity.Property(e => e.Title)
                .IsRequired()
                .HasMaxLength(200);

            entity.Property(e => e.Description)
                .HasMaxLength(5000);

            entity.Property(e => e.LocationAddress)
                .HasMaxLength(500);

            entity.HasIndex(e => e.StartsAtUtc);

            entity.HasOne(e => e.Organiser)
                .WithMany()
                .HasForeignKey(e => e.OrganiserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasMany(e => e.Attendees)
                .WithOne(a => a.Event)
                .HasForeignKey(a => a.EventId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasMany(e => e.ChatMessages)
                .WithOne(m => m.Event)
                .HasForeignKey(m => m.EventId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // ─── Event Attendees ─────────────────────────────────────────────────

        modelBuilder.Entity<EventAttendee>(entity =>
        {
            entity.ToTable("event_attendees");

            entity.HasKey(a => a.EventId);

            entity.HasIndex(a => new
            {
                a.EventId,
                a.UserId
            }).IsUnique();

            entity.HasOne(a => a.Event)
                .WithMany(e => e.Attendees)
                .HasForeignKey(a => a.EventId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(a => a.User)
                .WithMany()
                .HasForeignKey(a => a.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // ─── Event Chat Messages ─────────────────────────────────────────────

        modelBuilder.Entity<EventChatMessage>(entity =>
        {
            entity.ToTable("event_chat_messages");

            entity.HasKey(m => m.Id);

            entity.Property(m => m.Content)
                .IsRequired()
                .HasMaxLength(4000);

            entity.HasIndex(m => m.EventId);

            entity.HasOne(m => m.Event)
                .WithMany(e => e.ChatMessages)
                .HasForeignKey(m => m.EventId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(m => m.Sender)
                .WithMany()
                .HasForeignKey(m => m.SenderId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
