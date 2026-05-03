using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Unifye.Migrations
{
    /// <inheritdoc />
    public partial class AddSubscriptionHistoryMetadataJsonb : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "processed_stripe_events",
                schema: "development",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    StripeEventId = table.Column<string>(type: "text", nullable: false),
                    EventType = table.Column<string>(type: "text", nullable: false),
                    ProcessedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_processed_stripe_events", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "subscription_plans",
                schema: "development",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Tier = table.Column<int>(type: "integer", nullable: false),
                    DisplayName = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    BadgeLabel = table.Column<string>(type: "text", nullable: true),
                    BadgeColourHex = table.Column<string>(type: "text", nullable: true),
                    MonthlyPriceZar = table.Column<decimal>(type: "numeric", nullable: false),
                    AnnualPriceZar = table.Column<decimal>(type: "numeric", nullable: true),
                    StripeProductId = table.Column<string>(type: "text", nullable: true),
                    StripeMonthlyPriceId = table.Column<string>(type: "text", nullable: true),
                    StripeAnnualPriceId = table.Column<string>(type: "text", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_subscription_plans", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "plan_feature_permissions",
                schema: "development",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PlanId = table.Column<Guid>(type: "uuid", nullable: false),
                    Tier = table.Column<int>(type: "integer", nullable: false),
                    DailySwipeLimit = table.Column<int>(type: "integer", nullable: false),
                    MaxActiveMatches = table.Column<int>(type: "integer", nullable: false),
                    CanSeeWhoLikedMe = table.Column<bool>(type: "boolean", nullable: false),
                    CanSendMedia = table.Column<bool>(type: "boolean", nullable: false),
                    CanSendVoiceNotes = table.Column<bool>(type: "boolean", nullable: false),
                    HasReadReceipts = table.Column<bool>(type: "boolean", nullable: false),
                    WeeklyProfileBoostCount = table.Column<int>(type: "integer", nullable: false),
                    HasVerifiedOrganiserBadge = table.Column<bool>(type: "boolean", nullable: false),
                    MaxJoinedCommunities = table.Column<int>(type: "integer", nullable: false),
                    CanCreateCommunity = table.Column<bool>(type: "boolean", nullable: false),
                    MaxOwnedCommunities = table.Column<int>(type: "integer", nullable: false),
                    CommunityMemberCap = table.Column<int>(type: "integer", nullable: false),
                    CanCreateEvents = table.Column<bool>(type: "boolean", nullable: false),
                    MonthlyEventLimit = table.Column<int>(type: "integer", nullable: false),
                    EventAttendeeCap = table.Column<int>(type: "integer", nullable: true),
                    CanGenerateQrCheckin = table.Column<bool>(type: "boolean", nullable: false),
                    CanExportAttendees = table.Column<bool>(type: "boolean", nullable: false),
                    CanPinAnnouncements = table.Column<bool>(type: "boolean", nullable: false),
                    EventsPriorityListing = table.Column<bool>(type: "boolean", nullable: false),
                    AnalyticsAccess = table.Column<int>(type: "integer", nullable: false),
                    CanExportAnalyticsPdf = table.Column<bool>(type: "boolean", nullable: false),
                    MaxAccountAdmins = table.Column<int>(type: "integer", nullable: false),
                    CanBroadcastMessages = table.Column<bool>(type: "boolean", nullable: false),
                    HasWebhookAccess = table.Column<bool>(type: "boolean", nullable: false),
                    HasWhiteLabel = table.Column<bool>(type: "boolean", nullable: false),
                    HasSlaSupport = table.Column<bool>(type: "boolean", nullable: false),
                    HasDedicatedManager = table.Column<bool>(type: "boolean", nullable: false),
                    LeaderboardVisibilityCap = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_plan_feature_permissions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_plan_feature_permissions_subscription_plans_PlanId",
                        column: x => x.PlanId,
                        principalSchema: "development",
                        principalTable: "subscription_plans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "user_subscriptions",
                schema: "development",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    PlanId = table.Column<Guid>(type: "uuid", nullable: false),
                    Tier = table.Column<int>(type: "integer", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    StripeCustomerId = table.Column<string>(type: "text", nullable: true),
                    StripeSubscriptionId = table.Column<string>(type: "text", nullable: true),
                    StripePriceId = table.Column<string>(type: "text", nullable: true),
                    IsAnnualBilling = table.Column<bool>(type: "boolean", nullable: false),
                    CurrentPeriodStart = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    CurrentPeriodEnd = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    TrialStart = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    TrialEnd = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    CanceledAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    CancelAtPeriodEnd = table.Column<bool>(type: "boolean", nullable: false),
                    GracePeriodEnd = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_user_subscriptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_user_subscriptions_subscription_plans_PlanId",
                        column: x => x.PlanId,
                        principalSchema: "development",
                        principalTable: "subscription_plans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "subscription_history",
                schema: "development",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    SubscriptionId = table.Column<Guid>(type: "uuid", nullable: false),
                    PreviousTier = table.Column<int>(type: "integer", nullable: true),
                    NewTier = table.Column<int>(type: "integer", nullable: false),
                    PreviousStatus = table.Column<int>(type: "integer", nullable: true),
                    NewStatus = table.Column<int>(type: "integer", nullable: false),
                    ChangeReason = table.Column<string>(type: "text", nullable: true),
                    StripeEventId = table.Column<string>(type: "text", nullable: true),
                    Metadata = table.Column<Dictionary<string, object>>(type: "jsonb", nullable: true),
                    ChangedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_subscription_history", x => x.Id);
                    table.ForeignKey(
                        name: "FK_subscription_history_user_subscriptions_SubscriptionId",
                        column: x => x.SubscriptionId,
                        principalSchema: "development",
                        principalTable: "user_subscriptions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_plan_feature_permissions_PlanId",
                schema: "development",
                table: "plan_feature_permissions",
                column: "PlanId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_processed_stripe_events_StripeEventId",
                schema: "development",
                table: "processed_stripe_events",
                column: "StripeEventId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_subscription_history_SubscriptionId",
                schema: "development",
                table: "subscription_history",
                column: "SubscriptionId");

            migrationBuilder.CreateIndex(
                name: "IX_user_subscriptions_PlanId",
                schema: "development",
                table: "user_subscriptions",
                column: "PlanId");

            migrationBuilder.CreateIndex(
                name: "IX_user_subscriptions_StripeCustomerId",
                schema: "development",
                table: "user_subscriptions",
                column: "StripeCustomerId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_user_subscriptions_UserId",
                schema: "development",
                table: "user_subscriptions",
                column: "UserId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "plan_feature_permissions",
                schema: "development");

            migrationBuilder.DropTable(
                name: "processed_stripe_events",
                schema: "development");

            migrationBuilder.DropTable(
                name: "subscription_history",
                schema: "development");

            migrationBuilder.DropTable(
                name: "user_subscriptions",
                schema: "development");

            migrationBuilder.DropTable(
                name: "subscription_plans",
                schema: "development");
        }
    }
}
