using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Unifye.Migrations
{
    /// <inheritdoc />
    public partial class AddEventTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "events",
                schema: "development",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    OrganiserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "character varying(5000)", maxLength: 5000, nullable: true),
                    StartsAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndsAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    MaxAttendees = table.Column<int>(type: "integer", nullable: true),
                    LocationName = table.Column<string>(type: "text", nullable: true),
                    LocationAddress = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    LocationLatitude = table.Column<double>(type: "double precision", nullable: true),
                    LocationLongitude = table.Column<double>(type: "double precision", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_events", x => x.Id);
                    table.ForeignKey(
                        name: "FK_events_users_OrganiserId",
                        column: x => x.OrganiserId,
                        principalSchema: "development",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "event_attendees",
                schema: "development",
                columns: table => new
                {
                    EventId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    JoinedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsOrganiser = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_event_attendees", x => x.EventId);
                    table.ForeignKey(
                        name: "FK_event_attendees_events_EventId",
                        column: x => x.EventId,
                        principalSchema: "development",
                        principalTable: "events",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_event_attendees_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "development",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "event_chat_messages",
                schema: "development",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    EventId = table.Column<Guid>(type: "uuid", nullable: false),
                    SenderId = table.Column<Guid>(type: "uuid", nullable: false),
                    Content = table.Column<string>(type: "character varying(4000)", maxLength: 4000, nullable: false),
                    SentAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_event_chat_messages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_event_chat_messages_events_EventId",
                        column: x => x.EventId,
                        principalSchema: "development",
                        principalTable: "events",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_event_chat_messages_users_SenderId",
                        column: x => x.SenderId,
                        principalSchema: "development",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_conversations_UserTwoId",
                schema: "development",
                table: "conversations",
                column: "UserTwoId");

            migrationBuilder.CreateIndex(
                name: "IX_event_attendees_EventId_UserId",
                schema: "development",
                table: "event_attendees",
                columns: new[] { "EventId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_event_attendees_UserId",
                schema: "development",
                table: "event_attendees",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_event_chat_messages_EventId",
                schema: "development",
                table: "event_chat_messages",
                column: "EventId");

            migrationBuilder.CreateIndex(
                name: "IX_event_chat_messages_SenderId",
                schema: "development",
                table: "event_chat_messages",
                column: "SenderId");

            migrationBuilder.CreateIndex(
                name: "IX_events_OrganiserId",
                schema: "development",
                table: "events",
                column: "OrganiserId");

            migrationBuilder.CreateIndex(
                name: "IX_events_StartsAtUtc",
                schema: "development",
                table: "events",
                column: "StartsAtUtc");

            migrationBuilder.AddForeignKey(
                name: "FK_conversations_users_UserOneId",
                schema: "development",
                table: "conversations",
                column: "UserOneId",
                principalSchema: "development",
                principalTable: "users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_conversations_users_UserTwoId",
                schema: "development",
                table: "conversations",
                column: "UserTwoId",
                principalSchema: "development",
                principalTable: "users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_conversations_users_UserOneId",
                schema: "development",
                table: "conversations");

            migrationBuilder.DropForeignKey(
                name: "FK_conversations_users_UserTwoId",
                schema: "development",
                table: "conversations");

            migrationBuilder.DropTable(
                name: "event_attendees",
                schema: "development");

            migrationBuilder.DropTable(
                name: "event_chat_messages",
                schema: "development");

            migrationBuilder.DropTable(
                name: "events",
                schema: "development");

            migrationBuilder.DropIndex(
                name: "IX_conversations_UserTwoId",
                schema: "development",
                table: "conversations");
        }
    }
}
