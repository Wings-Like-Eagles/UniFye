using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Unifye.Migrations;

/// <inheritdoc />
public partial class SplitUserAuthAndProfile : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        // Schema was normalized to development + snake_case in the initial migration.
        // This migration remains as a no-op to preserve migration history.
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Intentionally empty.
    }
}
