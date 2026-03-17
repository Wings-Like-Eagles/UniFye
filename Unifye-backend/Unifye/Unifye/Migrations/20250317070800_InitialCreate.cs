using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace Unifye.Migrations;

/// <inheritdoc />
public partial class InitialCreate : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.EnsureSchema(
            name: "development");

        migrationBuilder.CreateTable(
            name: "users",
            schema: "development",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                Email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                PasswordHash = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_users", x => x.Id);
            });

        migrationBuilder.CreateTable(
            name: "user_matches",
            schema: "development",
            columns: table => new
            {
                Id = table.Column<int>(type: "integer", nullable: false)
                    .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                UserOneId = table.Column<Guid>(type: "uuid", nullable: false),
                UserTwoId = table.Column<Guid>(type: "uuid", nullable: false),
                CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_user_matches", x => x.Id);
            });

        migrationBuilder.CreateTable(
            name: "user_profiles",
            schema: "development",
            columns: table => new
            {
                UserId = table.Column<Guid>(type: "uuid", nullable: false),
                FirstName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                LastName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                Gender = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                DateOfBirth = table.Column<DateOnly>(type: "date", nullable: false),
                ImageUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_user_profiles", x => x.UserId);
                table.ForeignKey(
                    name: "FK_user_profiles_users_UserId",
                    column: x => x.UserId,
                    principalSchema: "development",
                    principalTable: "users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateTable(
            name: "user_swipes",
            schema: "development",
            columns: table => new
            {
                Id = table.Column<int>(type: "integer", nullable: false)
                    .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                SourceUserId = table.Column<Guid>(type: "uuid", nullable: false),
                TargetUserId = table.Column<Guid>(type: "uuid", nullable: false),
                IsLiked = table.Column<bool>(type: "boolean", nullable: false),
                CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_user_swipes", x => x.Id);
            });

        migrationBuilder.CreateIndex(
            name: "IX_user_matches_UserOneId_UserTwoId",
            schema: "development",
            table: "user_matches",
            columns: new[] { "UserOneId", "UserTwoId" },
            unique: true);

        migrationBuilder.CreateIndex(
            name: "IX_users_Email",
            schema: "development",
            table: "users",
            column: "Email",
            unique: true);

        migrationBuilder.CreateIndex(
            name: "IX_user_swipes_SourceUserId_TargetUserId",
            schema: "development",
            table: "user_swipes",
            columns: new[] { "SourceUserId", "TargetUserId" },
            unique: true);

        migrationBuilder.CreateTable(
            name: "user_interests",
            schema: "development",
            columns: table => new
            {
                Id = table.Column<int>(type: "integer", nullable: false)
                    .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                UserProfileId = table.Column<Guid>(type: "uuid", nullable: false),
                Interest = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_user_interests", x => x.Id);
                table.ForeignKey(
                    name: "FK_user_interests_user_profiles_UserProfileId",
                    column: x => x.UserProfileId,
                    principalSchema: "development",
                    principalTable: "user_profiles",
                    principalColumn: "UserId",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateIndex(
            name: "IX_user_interests_UserProfileId",
            schema: "development",
            table: "user_interests",
            column: "UserProfileId");
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(
            name: "user_interests",
            schema: "development");

        migrationBuilder.DropTable(
            name: "user_matches",
            schema: "development");

        migrationBuilder.DropTable(
            name: "user_profiles",
            schema: "development");

        migrationBuilder.DropTable(
            name: "user_swipes",
            schema: "development");

        migrationBuilder.DropTable(
            name: "users",
            schema: "development");
    }
}
