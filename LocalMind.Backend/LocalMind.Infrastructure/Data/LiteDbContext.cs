using LiteDB;
using LocalMind.Core.Entities;
using Microsoft.Extensions.Configuration;

namespace LocalMind.Infrastructure.Data;

public class LiteDbContext : IDisposable
{
    public LiteDatabase Database { get; }

    public LiteDbContext(IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString) || connectionString.StartsWith("Data Source="))
        {
            connectionString = "Filename=localmind_nosql.db;Connection=shared";
        }

        // Ensure target directory exists
        if (connectionString.Contains("Filename="))
        {
            var parts = connectionString.Split(';');
            var filePart = parts.FirstOrDefault(p => p.StartsWith("Filename="));
            if (filePart != null)
            {
                var filePath = filePart.Substring("Filename=".Length);
                var dir = Path.GetDirectoryName(filePath);
                if (!string.IsNullOrWhiteSpace(dir) && !Directory.Exists(dir))
                {
                    Directory.CreateDirectory(dir);
                }
            }
        }

        Database = new LiteDatabase(connectionString);

        // Configure Bson Mappings & Indexes
        var sessionCol = Database.GetCollection<ChatSession>("sessions");
        sessionCol.EnsureIndex(x => x.Id, true);
        sessionCol.EnsureIndex(x => x.LastUpdatedAt);

        var messageCol = Database.GetCollection<ChatMessage>("messages");
        messageCol.EnsureIndex(x => x.Id, true);
        messageCol.EnsureIndex(x => x.SessionId);
        messageCol.EnsureIndex(x => x.Timestamp);
    }

    public ILiteCollection<ChatSession> Sessions => Database.GetCollection<ChatSession>("sessions");
    public ILiteCollection<ChatMessage> Messages => Database.GetCollection<ChatMessage>("messages");

    public void Dispose()
    {
        Database?.Dispose();
    }
}
