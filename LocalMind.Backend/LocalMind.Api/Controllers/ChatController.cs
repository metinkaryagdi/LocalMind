using System.Text;
using System.Text.Json;
using LocalMind.Core.Dtos;
using LocalMind.Core.Entities;
using LocalMind.Core.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace LocalMind.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ChatController : ControllerBase
{
    private readonly IOllamaClientService _ollamaClientService;
    private readonly IChatRepository _chatRepository;
    private readonly ILogger<ChatController> _logger;

    public ChatController(
        IOllamaClientService ollamaClientService,
        IChatRepository chatRepository,
        ILogger<ChatController> logger)
    {
        _ollamaClientService = ollamaClientService;
        _chatRepository = chatRepository;
        _logger = logger;
    }

    [HttpGet("health")]
    public async Task<IActionResult> HealthCheck(CancellationToken cancellationToken)
    {
        var isOllamaUp = await _ollamaClientService.IsServerAvailableAsync(cancellationToken);
        return Ok(new
        {
            Status = isOllamaUp ? "Healthy" : "Degraded",
            OllamaAvailable = isOllamaUp,
            Timestamp = DateTime.UtcNow
        });
    }

    [HttpGet("sessions")]
    public async Task<IActionResult> GetSessions(CancellationToken cancellationToken)
    {
        var sessions = await _chatRepository.GetSessionsAsync(cancellationToken);
        var dtos = sessions.Select(s => new ChatSessionDto(
            s.Id,
            s.Title,
            s.CreatedAt,
            s.LastUpdatedAt,
            s.Messages.Count
        ));
        return Ok(dtos);
    }

    [HttpPost("sessions")]
    public async Task<IActionResult> CreateSession([FromBody] CreateSessionRequestDto request, CancellationToken cancellationToken)
    {
        var title = string.IsNullOrWhiteSpace(request.Title) ? "New Conversation" : request.Title;
        var session = await _chatRepository.GetOrCreateSessionAsync(null, title, cancellationToken);
        return Ok(new ChatSessionDto(session.Id, session.Title, session.CreatedAt, session.LastUpdatedAt, 0));
    }

    [HttpGet("history/{sessionId:guid}")]
    public async Task<IActionResult> GetHistory(Guid sessionId, CancellationToken cancellationToken)
    {
        var session = await _chatRepository.GetSessionByIdAsync(sessionId, cancellationToken);
        if (session == null)
        {
            return NotFound(new { Message = "Session not found" });
        }

        var messages = session.Messages.Select(m => new ChatMessageDto(
            m.Id,
            m.SessionId,
            m.Role,
            m.Content,
            m.Timestamp
        ));

        return Ok(new
        {
            SessionId = session.Id,
            Title = session.Title,
            Messages = messages
        });
    }

    [HttpDelete("sessions/{sessionId:guid}")]
    public async Task<IActionResult> DeleteSession(Guid sessionId, CancellationToken cancellationToken)
    {
        await _chatRepository.DeleteSessionAsync(sessionId, cancellationToken);
        return NoContent();
    }

    [HttpPost("stream")]
    public async Task StreamChat([FromBody] ChatRequestDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Message))
        {
            Response.StatusCode = StatusCodes.Status400BadRequest;
            await Response.WriteAsync("Message content cannot be empty", cancellationToken);
            return;
        }

        // 1. Load or create session
        var session = await _chatRepository.GetOrCreateSessionAsync(request.SessionId, cancellationToken: cancellationToken);

        // 2. Persist user message
        var userMsg = new ChatMessage
        {
            Id = Guid.NewGuid(),
            SessionId = session.Id,
            Role = "user",
            Content = request.Message,
            Timestamp = DateTime.UtcNow
        };
        await _chatRepository.AddMessageAsync(userMsg, cancellationToken);
        await _chatRepository.SaveChangesAsync(cancellationToken);

        // 3. Build context history (last 10 messages)
        var previousMessages = await _chatRepository.GetSessionMessagesAsync(session.Id, maxCount: 10, cancellationToken: cancellationToken);
        var ollamaContext = new List<OllamaChatMessage>
        {
            new OllamaChatMessage("system", "You are LocalMind, an intelligent, helpful, and concise local AI assistant running on a local LAN server.")
        };

        foreach (var msg in previousMessages)
        {
            ollamaContext.Add(new OllamaChatMessage(msg.Role, msg.Content));
        }

        // 4. Setup SSE Response headers
        Response.Headers.Append("Content-Type", "text/event-stream");
        Response.Headers.Append("Cache-Control", "no-cache");
        Response.Headers.Append("Connection", "keep-alive");

        // Send Session metadata header token first
        var sessionHeaderJson = JsonSerializer.Serialize(new { sessionId = session.Id });
        await Response.WriteAsync($"data: [SESSION_META]{sessionHeaderJson}\n\n", cancellationToken);
        await Response.Body.FlushAsync(cancellationToken);

        var fullAssistantResponse = new StringBuilder();

        // 5. Stream from Ollama and yield to HTTP SSE client
        await foreach (var token in _ollamaClientService.StreamChatAsync(ollamaContext, request.ModelOverride, cancellationToken))
        {
            fullAssistantResponse.Append(token);

            // Escape newlines for SSE standard format or format token as JSON data line
            var dataPayload = JsonSerializer.Serialize(new { token });
            await Response.WriteAsync($"data: {dataPayload}\n\n", cancellationToken);
            await Response.Body.FlushAsync(cancellationToken);
        }

        // Send Done marker
        await Response.WriteAsync("data: [DONE]\n\n", cancellationToken);
        await Response.Body.FlushAsync(cancellationToken);

        // 6. Save complete assistant response to SQLite DB
        if (fullAssistantResponse.Length > 0)
        {
            var assistantMsg = new ChatMessage
            {
                Id = Guid.NewGuid(),
                SessionId = session.Id,
                Role = "assistant",
                Content = fullAssistantResponse.ToString(),
                Timestamp = DateTime.UtcNow
            };
            await _chatRepository.AddMessageAsync(assistantMsg, CancellationToken.None);
            await _chatRepository.SaveChangesAsync(CancellationToken.None);
        }
    }
}
