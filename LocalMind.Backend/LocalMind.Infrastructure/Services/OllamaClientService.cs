using System.Runtime.CompilerServices;
using System.Text;
using System.Text.Json;
using LocalMind.Core.Dtos;
using LocalMind.Core.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace LocalMind.Infrastructure.Services;

public class OllamaClientService : IOllamaClientService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<OllamaClientService> _logger;
    private readonly string _defaultModel;

    public OllamaClientService(HttpClient httpClient, IConfiguration configuration, ILogger<OllamaClientService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
        _defaultModel = _configuration["Ollama:DefaultModel"] ?? "llama3.2:3b";
    }

    public async Task<bool> IsServerAvailableAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync("/api/tags", cancellationToken);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to connect to Ollama server at base address {BaseAddress}", _httpClient.BaseAddress);
            return false;
        }
    }

    public async IAsyncEnumerable<string> StreamChatAsync(
        List<OllamaChatMessage> contextHistory,
        string? modelOverride = null,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        var model = string.IsNullOrWhiteSpace(modelOverride) ? _defaultModel : modelOverride;
        var requestPayload = new OllamaChatRequest(model, contextHistory, stream: true);

        var json = JsonSerializer.Serialize(requestPayload);
        using var content = new StringContent(json, Encoding.UTF8, "application/json");

        using var request = new HttpRequestMessage(HttpMethod.Post, "/api/chat")
        {
            Content = content
        };

        HttpResponseMessage? response = null;
        string? errorMessage = null;
        try
        {
            response = await _httpClient.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
            response.EnsureSuccessStatusCode();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error initiating HTTP streaming request to Ollama endpoint");
            errorMessage = $" [Error connecting to Ollama service: {ex.Message}]";
        }

        if (errorMessage != null)
        {
            yield return errorMessage;
            yield break;
        }

        if (response == null) yield break;

        using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var reader = new StreamReader(stream, Encoding.UTF8);

        while (!reader.EndOfStream && !cancellationToken.IsCancellationRequested)
        {
            var line = await reader.ReadLineAsync(cancellationToken);
            if (string.IsNullOrWhiteSpace(line)) continue;

            OllamaStreamResponseChunk? chunk = null;
            try
            {
                chunk = JsonSerializer.Deserialize<OllamaStreamResponseChunk>(line);
            }
            catch (JsonException ex)
            {
                _logger.LogWarning(ex, "Failed to parse stream JSON line: {Line}", line);
                continue;
            }

            if (chunk?.message?.content != null)
            {
                yield return chunk.message.content;
            }

            if (chunk?.done == true)
            {
                break;
            }
        }
    }
}
