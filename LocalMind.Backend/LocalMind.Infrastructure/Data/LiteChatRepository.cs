using LiteDB;
using LocalMind.Core.Entities;
using LocalMind.Core.Interfaces;

namespace LocalMind.Infrastructure.Data;

public class LiteChatRepository : IChatRepository
{
    private readonly LiteDbContext _dbContext;

    public LiteChatRepository(LiteDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<ChatSession> GetOrCreateSessionAsync(Guid? sessionId, string defaultTitle = "New Conversation", CancellationToken cancellationToken = default)
    {
        if (sessionId.HasValue && sessionId.Value != Guid.Empty)
        {
            var existing = _dbContext.Sessions.FindOne(x => x.Id == sessionId.Value);
            if (existing != null)
            {
                existing.Messages = _dbContext.Messages
                    .Find(x => x.SessionId == existing.Id)
                    .OrderBy(m => m.Timestamp)
                    .ToList();
                return Task.FromResult(existing);
            }
        }

        var session = new ChatSession
        {
            Id = sessionId ?? Guid.NewGuid(),
            Title = defaultTitle,
            CreatedAt = DateTime.UtcNow,
            LastUpdatedAt = DateTime.UtcNow,
            Messages = new List<ChatMessage>()
        };

        _dbContext.Sessions.Insert(session);
        return Task.FromResult(session);
    }

    public Task<List<ChatSession>> GetSessionsAsync(CancellationToken cancellationToken = default)
    {
        var sessions = _dbContext.Sessions.FindAll()
            .OrderByDescending(s => s.LastUpdatedAt)
            .ToList();

        foreach (var s in sessions)
        {
            s.Messages = _dbContext.Messages
                .Find(x => x.SessionId == s.Id)
                .ToList();
        }

        return Task.FromResult(sessions);
    }

    public Task<ChatSession?> GetSessionByIdAsync(Guid sessionId, CancellationToken cancellationToken = default)
    {
        var session = _dbContext.Sessions.FindOne(x => x.Id == sessionId);
        if (session != null)
        {
            session.Messages = _dbContext.Messages
                .Find(x => x.SessionId == session.Id)
                .OrderBy(m => m.Timestamp)
                .ToList();
        }
        return Task.FromResult(session);
    }

    public Task DeleteSessionAsync(Guid sessionId, CancellationToken cancellationToken = default)
    {
        _dbContext.Messages.DeleteMany(x => x.SessionId == sessionId);
        _dbContext.Sessions.DeleteMany(x => x.Id == sessionId);
        return Task.CompletedTask;
    }

    public Task<List<ChatMessage>> GetSessionMessagesAsync(Guid sessionId, int maxCount = 20, CancellationToken cancellationToken = default)
    {
        var messages = _dbContext.Messages
            .Find(x => x.SessionId == sessionId)
            .OrderByDescending(m => m.Timestamp)
            .Take(maxCount)
            .OrderBy(m => m.Timestamp)
            .ToList();

        return Task.FromResult(messages);
    }

    public Task AddMessageAsync(ChatMessage message, CancellationToken cancellationToken = default)
    {
        _dbContext.Messages.Insert(message);

        var session = _dbContext.Sessions.FindOne(x => x.Id == message.SessionId);
        if (session != null)
        {
            session.LastUpdatedAt = DateTime.UtcNow;
            if (session.Title == "New Conversation" && message.Role == "user" && !string.IsNullOrWhiteSpace(message.Content))
            {
                session.Title = message.Content.Length > 30 ? message.Content[..30] + "..." : message.Content;
            }
            _dbContext.Sessions.Update(session);
        }

        return Task.CompletedTask;
    }

    public Task SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        // LiteDB auto-commits operations in shared mode
        return Task.CompletedTask;
    }
}
