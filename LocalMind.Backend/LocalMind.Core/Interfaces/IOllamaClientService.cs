using LocalMind.Core.Dtos;

namespace LocalMind.Core.Interfaces;

public interface IOllamaClientService
{
    IAsyncEnumerable<string> StreamChatAsync(
        List<OllamaChatMessage> contextHistory, 
        string? modelOverride = null, 
        CancellationToken cancellationToken = default);
        
    Task<bool> IsServerAvailableAsync(CancellationToken cancellationToken = default);
}
