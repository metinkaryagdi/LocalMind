using LocalMind.Core.Entities;

namespace LocalMind.Core.Interfaces;

public interface IChatRepository
{
    Task<ChatSession> GetOrCreateSessionAsync(Guid? sessionId, string defaultTitle = "New Conversation", CancellationToken cancellationToken = default);
    Task<List<ChatSession>> GetSessionsAsync(CancellationToken cancellationToken = default);
    Task<ChatSession?> GetSessionByIdAsync(Guid sessionId, CancellationToken cancellationToken = default);
    Task DeleteSessionAsync(Guid sessionId, CancellationToken cancellationToken = default);
    Task<List<ChatMessage>> GetSessionMessagesAsync(Guid sessionId, int maxCount = 20, CancellationToken cancellationToken = default);
    Task AddMessageAsync(ChatMessage message, CancellationToken cancellationToken = default);
    Task SaveChangesAsync(CancellationToken cancellationToken = default);
}
