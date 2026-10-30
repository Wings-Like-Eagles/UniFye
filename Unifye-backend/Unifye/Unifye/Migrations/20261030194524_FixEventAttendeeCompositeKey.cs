using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Unifye.Migrations
{
    /// <inheritdoc />
    public partial class FixEventAttendeeCompositeKey : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropPrimaryKey(
                name: "PK_event_attendees",
                schema: "development",
                table: "event_attendees");

            migrationBuilder.DropIndex(
                name: "IX_event_attendees_EventId_UserId",
                schema: "development",
                table: "event_attendees");

            migrationBuilder.AddPrimaryKey(
                name: "PK_event_attendees",
                schema: "development",
                table: "event_attendees",
                columns: new[] { "EventId", "UserId" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropPrimaryKey(
                name: "PK_event_attendees",
                schema: "development",
                table: "event_attendees");

            migrationBuilder.AddPrimaryKey(
                name: "PK_event_attendees",
                schema: "development",
                table: "event_attendees",
                column: "EventId");

            migrationBuilder.CreateIndex(
                name: "IX_event_attendees_EventId_UserId",
                schema: "development",
                table: "event_attendees",
                columns: new[] { "EventId", "UserId" },
                unique: true);
        }
    }
}
