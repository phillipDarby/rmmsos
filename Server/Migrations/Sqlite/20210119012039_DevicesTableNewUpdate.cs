using Microsoft.EntityFrameworkCore.Migrations;

namespace Remotely.Server.Migrations.Sqlite
{
    public partial class DevicesTableNewUpdate : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Processes",
                table: "Devices",
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Processes",
                table: "Devices");
        }
    }
}
