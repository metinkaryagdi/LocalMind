using LocalMind.Core.Interfaces;
using LocalMind.Infrastructure.Data;
using LocalMind.Infrastructure.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure NoSQL Database Context (LiteDB)
builder.Services.AddSingleton<LiteDbContext>();
builder.Services.AddScoped<IChatRepository, LiteChatRepository>();

// Configure HttpClient for Ollama Service
var ollamaBaseUrl = builder.Configuration["Ollama:BaseUrl"] ?? "http://192.168.1.50:11434";
builder.Services.AddHttpClient<IOllamaClientService, OllamaClientService>(client =>
{
    client.BaseAddress = new Uri(ollamaBaseUrl);
    client.Timeout = TimeSpan.FromMinutes(5); // Long timeout for SLM streaming
});

// Configure CORS for Mobile Client LAN access
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAllLAN", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment() || true)
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAllLAN");
app.UseAuthorization();
app.MapControllers();

app.Run();
