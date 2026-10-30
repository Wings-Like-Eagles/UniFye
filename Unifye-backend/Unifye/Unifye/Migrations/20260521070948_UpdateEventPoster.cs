using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Unifye.Migrations
{
    /// <inheritdoc />
    public partial class UpdateEventPoster : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PosterUrl",
                schema: "development",
                table: "events",
                type: "text",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PosterUrl",
                schema: "development",
                table: "events");
        }
    }
}
