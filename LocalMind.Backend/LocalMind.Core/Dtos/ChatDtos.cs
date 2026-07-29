namespace LocalMind.Core.Dtos;

public record ChatRequestDto(
    Guid? SessionId,
    string Message,
    string? ModelOverride = null
);

public record ChatMessageDto(
    Guid Id,
    Guid SessionId,
    string Role,
    string Content,
    DateTime Timestamp
);

public record ChatSessionDto(
    Guid Id,
    string Title,
    DateTime CreatedAt,
    DateTime LastUpdatedAt,
    int MessageCount
);

public record CreateSessionRequestDto(
    string? Title
);

// Ollama native payload formats
public record OllamaChatMessage(
    string role,
    string content
);

public record OllamaChatRequest(
    string model,
    List<OllamaChatMessage> messages,
    bool stream = true
);

public record OllamaStreamResponseChunk(
    string model,
    string created_at,
    OllamaChatMessage message,
    bool done
);
